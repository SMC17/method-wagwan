const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("wagwan", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "wagwan",
        .root_module = mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("wagwan", mod);
    const exe = b.addExecutable(.{
        .name = "wagwan",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the wagwan deterministic replay demo");
    run_step.dependOn(&run_cmd.step);

    const score_mod = b.createModule(.{
        .root_source_file = b.path("src/score_main.zig"),
        .target = target,
        .optimize = optimize,
    });
    score_mod.addImport("wagwan", mod);
    const score_exe = b.addExecutable(.{ .name = "wagwan-score", .root_module = score_mod });
    b.installArtifact(score_exe);
    const score_run = b.addRunArtifact(score_exe);
    if (b.args) |args| score_run.addArgs(args);
    b.step("score", "Score a CSV of forecasts: zig build score -- forecasts.csv").dependOn(&score_run.step);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&run_tests.step);
}
