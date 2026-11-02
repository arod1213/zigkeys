const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const keys = b.addModule("keys", .{
        .root_source_file = b.path("src/keys/main.zig"),
        .target = target,
        .imports = &.{},
    });
    const core_graphics = b.addTranslateC(.{
        .root_source_file = b.path("src/include/coregraphics.h"),
        .target = target,
        .optimize = optimize,
    });
    keys.addImport("CoreGraphics", core_graphics.createModule());
    keys.linkFramework("CoreGraphics", .{ .needed = true });
    keys.linkFramework("CoreFoundation", .{ .needed = true });

    const mod = b.addModule("zigkeys", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "keys", .module = keys },
        },
    });

    const exe = b.addExecutable(.{
        .name = "zigkeys",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zigkeys", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
