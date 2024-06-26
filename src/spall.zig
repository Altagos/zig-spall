const std = @import("std");
const builtin = @import("builtin");

var pid: i32 = undefined;
var ctx: Profile = undefined;

threadlocal var tid: i32 = undefined;
threadlocal var buffer: ?Buffer = undefined;
threadlocal var started: bool = false;

pub fn init(filename: []const u8) !void {
    pid = getPid();
    ctx = try Profile.init(filename, 1.0);
}

fn getPid() i32 {
    return switch (builtin.os.tag) {
        .linux, .macos, .ios, .watchos, .tvos => std.os.linux.getpid(),
        // .macos, .ios, .watchos, .tvos => try std.os.darwin.machTaskForSelf().pidForTask(),
        .windows => std.os.windows.kernel32.GetCurrentProcessId(),
        else => 0,
    };
}

pub fn deinit() void {
    if (ctx.file) |file| {
        file.close();
    }
}

pub fn init_thread() void {
    if (!started) {
        tid = switch (builtin.os.tag) {
            .linux => std.os.linux.gettid(),
            .windows => std.os.windows.kernel32.GetCurrentThreadId(),
            else => @intCast(std.Thread.getCurrentId()),
        };

        buffer = Buffer.init(&ctx);
        started = true;
    }
}

pub fn deinit_thread() void {
    if (buffer) |*b| {
        b.quit();
    }
    started = false;
}

pub const Span = struct {
    src: std.builtin.SourceLocation,

    pub inline fn end(self: Span) void {
        if (started) trace_end(self);
    }
};

pub inline fn trace(src: std.builtin.SourceLocation, comptime fmt: []const u8, args: anytype) Span {
    const span = Span{ .src = src };
    if (started) trace_begin(span, fmt, args);
    return span;
}

pub inline fn trace_begin(span: Span, comptime ifmt: []const u8, iargs: anytype) void {
    if (buffer) |*b| {
        const fmt = "{s}:{d}:{d} ({s}) " ++ ifmt;
        const args = .{
            span.src.file,
            span.src.line,
            span.src.column,
            span.src.fn_name,
        };
        b.writer.writer().writeStruct(BeginEvent{
            .pid = @intCast(pid),
            .tid = @intCast(tid),
            .when = @floatFromInt(std.time.microTimestamp()),
            .name_lenght = @intCast(std.fmt.count(fmt, args ++ iargs)),
            .args_lenght = 0,
        }) catch return;
        b.writer.writer().print(fmt, args ++ iargs) catch return;
    }
}

pub inline fn trace_end(span: Span) void {
    _ = span;

    if (buffer) |*b| {
        b.writer.writer().writeStruct(EndEvent{
            .pid = @intCast(pid),
            .tid = @intCast(tid),
            .when = @floatFromInt(std.time.microTimestamp()),
        }) catch return;
    }
}

const magic: u64 = 0x0BADF00D;

pub const Header = extern struct {
    magic_header: u64 align(1) = magic,
    version: u64 align(1) = 1,
    timestamp_unit: f64 align(1) = 1.0,
    must_be_0: u64 align(1) = 0,
};

pub const EventType = enum(u8) {
    invalid = 0,
    custom_data = 1,
    stream_over = 2,

    begin = 3,
    end = 4,
    instant = 5,

    overwrite_timestamp = 6, // Retroactively change timestamp units - useful for incrementally improving RDTSC frequency.
    pad_skip = 7,
};

pub const BeginEvent = extern struct {
    type: EventType align(1) = .begin,
    category: u8 align(1) = 0,

    pid: u32 align(1),
    tid: u32 align(1),
    when: f64 align(1),

    name_lenght: u8 align(1),
    args_lenght: u8 align(1),
};

pub const BeginEventMax = extern struct {
    event: BeginEvent align(1),
    name_bytes: [255]u8 align(1),
    args_bytes: [255]u8 align(1),
};

pub const EndEvent = extern struct {
    type: EventType align(1) = .end,
    pid: u32 align(1),
    tid: u32 align(1),
    when: f64 align(1),
};

pub const SkipEvent = extern struct {
    type: EventType align(1) = .pad_skip,
    size: u32 align(1),
};

pub const Profile = struct {
    timestamp_unit: f64,
    is_json: bool = false,
    file: ?std.fs.File = null,

    pub fn init(filename: []const u8, timestamp_unit: f64) !Profile {
        const file = try std.fs.cwd().createFile(filename, .{
            .truncate = true,
            .lock = .shared,
        });
        try file.writer().writeStruct(Header{ .timestamp_unit = timestamp_unit });
        return .{ .file = file, .timestamp_unit = timestamp_unit };
    }
};

pub const Buffer = struct {
    ctx: ?*Profile = null,
    writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

    pub fn init(bctx: *Profile) ?Buffer {
        if (bctx.file) |file| {
            const writer = std.io.bufferedWriter(file.writer());
            return .{ .ctx = bctx, .writer = writer };
        }
        return null;
    }

    pub fn quit(self: *Buffer) void {
        self.flush() catch |err| {
            std.debug.print("Error while flushing buffer: {}", .{err});
        };
        self.ctx = null;
    }

    pub fn abort(self: *const Buffer) !void {
        if (self != null) return false;
        self.ctx = null;
        try self.flush();
    }

    pub inline fn flush(self: *const Buffer) !void {
        var writer = @constCast(&self.writer);
        try writer.flush();
    }
};
