const std = @import("std");
const spall = @import("spall");

test "init thread" {
    try spall.init("./test.spall");
    defer spall.deinit();

    spall.init_thread();
    defer spall.deinit_thread();
}
