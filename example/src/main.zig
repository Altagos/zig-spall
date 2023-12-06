const std = @import("std");
const spall = @import("spall");

threadlocal var tid: std.Thread.Id = undefined;

pub fn main() !void {
    try spall.init("./trace/example.spall");
    defer spall.deinit();

    const thread_1 = try std.Thread.spawn(.{}, run_work, .{});
    const thread_2 = try std.Thread.spawn(.{}, run_work, .{});

    thread_1.join();
    thread_2.join();
}

fn run_work() !void {
    tid = std.Thread.getCurrentId();

    spall.init_thread();
    defer spall.deinit_thread();

    for (0..1000000) |_| {
        foo();
    }
}

fn bar() void {
    const s = spall.trace(@src(), "", .{});
    defer s.end();
}

fn foo() void {
    const s = spall.trace(@src(), "", .{});
    defer s.end();

    bar();
}
