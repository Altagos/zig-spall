const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spall_enable = b.option(bool, "enable", "Enable spall profiling") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "enable", spall_enable);

    const spall_module = b.addModule("spall", .{
        .source_file = .{ .path = if (spall_enable) "./src/spall.zig" else "./src/nop.zig" },
        .dependencies = &.{.{
            .name = "spall-options",
            .module = options.createModule(),
        }},
    });

    const spall_lib = b.addStaticLibrary(.{
        .name = "spall",
        .target = target,
        .optimize = optimize,
    });
    spall_lib.addModule("spall", spall_module);

    b.installArtifact(spall_lib);
}
