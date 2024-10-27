const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .bpf,
            .os_tag = .solana,
            .abi = .bpf,
        },
    });

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const lib = b.addSharedLibrary(.{
        .name = "native-amm",
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add Solana SDK dependency
    const solana_dep = b.dependency("solana", .{});
    lib.addModule("solana", solana_dep.module("solana"));

    // Install the library
    b.installArtifact(lib);

    // Create tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    main_tests.addModule("solana", solana_dep.module("solana"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}