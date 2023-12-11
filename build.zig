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

    const spall_lib = b.addSharedLibrary(.{
        .name = "spall",
        .root_source_file = .{ .path = "./src/spall.zig" },
        .target = target,
        .optimize = optimize,
    });
    spall_lib.dll_export_fns = true;
    spall_lib.addModule("spall-options", options.createModule());

    b.installArtifact(spall_lib);

    const test_step = b.step("test", "Run unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "./src/test.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addModule("spall", spall_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
