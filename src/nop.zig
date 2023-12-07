const std = @import("std");

pub inline fn init(filename: []const u8) !void {
    _ = filename;
}

pub inline fn deinit() void {}

pub inline fn init_thread() void {}

pub inline fn deinit_thread() void {}

pub const Span = struct {
    pub inline fn end(self: Span) void {
        _ = self;
    }
};

pub inline fn trace(src: std.builtin.SourceLocation, comptime fmt: []const u8, args: anytype) Span {
    _ = src;
    _ = fmt;
    _ = args;
    return .{};
}

pub inline fn trace_begin(span: Span, comptime ifmt: []const u8, iargs: anytype) void {
    _ = span;
    _ = ifmt;
    _ = iargs;
}

pub inline fn trace_end(span: Span) void {
    _ = span;
}
