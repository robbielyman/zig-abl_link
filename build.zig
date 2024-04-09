const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("zig-abl_link", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "lib.zig" },
    });

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "lib.zig" },
    });

    const lib = try compileAblLink(b, target, optimize);
    module.linkLibrary(lib);
    tests.linkLibrary(lib);
    b.installArtifact(lib);

    const tests_run = b.addRunArtifact(tests);
    const tests_step = b.step("test", "run tests");
    tests_step.dependOn(&tests_run.step);
}

fn compileAblLink(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "abl_link",
    });
    lib.linkLibCpp();
    lib.linkLibC();
    const upstream = b.dependency("upstream", .{});

    const t = target.result.os.tag;

    switch (t) {
        .macos => lib.defineCMacro("LINK_PLATFORM_MACOSX", "1"),
        .linux => lib.defineCMacro("LINK_PLATFORM_LINUX", "1"),
        .windows => lib.defineCMacro("LINK_PLATFORM_WINDOWS", "1"),
        else => return error.NotSupported,
    }

    lib.addIncludePath(.{ .dependency = .{
        .dependency = upstream,
        .sub_path = "extensions/abl_link/include",
    } });
    lib.addIncludePath(.{ .dependency = .{
        .dependency = upstream,
        .sub_path = "include",
    } });
    lib.addCSourceFile(.{
        .file = .{ .dependency = .{
            .dependency = upstream,
            .sub_path = "extensions/abl_link/src/abl_link.cpp",
        } },
        .flags = &.{"-std=c++11"},
    });

    lib.linkSystemLibrary("asio");

    return lib;
}
