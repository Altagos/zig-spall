const std = @import("std");
const spall = @import("spall");

test "init thread" {
    try spall.init("./test_init_thread.spall");
    defer spall.deinit();

    spall.init_thread();
    defer spall.deinit_thread();

    const t = spall.trace(@src(), "test", .{});
    defer t.end();

    std.time.sleep(10);
}
