const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spall_module = b.addModule("spall", .{
        .source_file = .{ .path = "./src/spall.zig" },
        .dependencies = &.{},
    });

    const spall_lib = b.addStaticLibrary(.{
        .name = "spall",
        .target = target,
        .optimize = optimize,
    });
    spall_lib.addModule("spall", spall_module);

    b.installArtifact(spall_lib);
}
