const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // This enables benchmarks
    const enable_benchmarks = b.option(bool, "benchmarks", "Enable benchmark builds") orelse false;
    // This enables profiling
    const enable_profiling = b.option(bool, "profiling", "Enable profiling support") orelse false;
    // This enables verbose logging
    const enable_verbose = b.option(bool, "verbose", "Enable verbose logging") orelse false;

    // This creates a "module", which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Every executable or library we compile will be based on one or more modules.
    const lib_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add build options to the library module
    const build_options = b.addOptions();
    build_options.addOption(bool, "enable_benchmarks", enable_benchmarks);
    build_options.addOption(bool, "enable_profiling", enable_profiling);
    build_options.addOption(bool, "enable_verbose", enable_verbose);
    lib_mod.addImport("build_options", build_options.createModule());

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Modules can depend on one another using the `std.Build.Module.addImport` function.
    // This is what allows Zig source code to use `@import("foo")` where 'foo' is not a
    // file path. In this case, we set up `exe_mod` to import `lib_mod`.
    exe_mod.addImport("fasten_lib", lib_mod);

    // Add the build imports to the executable module
    exe_mod.addImport("build_options", build_options.createModule());

    // Now, we will create a static library based on the module we created above.
    // This creates a `std.Build.Step.Compile`, which is the build step responsible
    // for actually invoking the compiler.
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "fasten",
        .root_module = lib_mod,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // This creates another `std.Build.Step.Compile`, but this one builds an executable
    // rather than a static library.
    const exe = b.addExecutable(.{
        .name = "fasten",
        .root_module = exe_mod,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the Fasten executable");
    run_step.dependOn(&run_cmd.step);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // Test steps
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    // Custom Fasten build steps

    // Benchmark step
    if (enable_benchmarks) {
        const bench_exe = b.addExecutable(.{
            .name = "fasten-bench",
            .root_source_file = b.path("benchmarks/main.zig"),
            .target = target,
            .optimize = .ReleaseFast, // Always optimize benchmarks
        });
        bench_exe.root_module.addImport("fasten_lib", lib_mod);

        const run_bench = b.addRunArtifact(bench_exe);
        const bench_step = b.step("bench", "Run performance benchmarks");
        bench_step.dependOn(&run_bench.step);
    }

    // Documentation step
    const docs = b.addTest(.{
        .root_module = lib_mod,
    });
    docs.root_module.strip = false;
    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&b.addInstallDirectory(.{
        .source_dir = docs.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    }).step);

    // Clean step (remove all build artifacts) - not needed for now
    // const clean_step = b.step("clean", "Remove build artifacts");
    // Note: Zig automatically cleans zig-cache and zig-out, but we can add custom cleanup here if needed

    // Release builds with different optimization levels
    const release_safe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });
    release_safe_mod.addImport("fasten_lib", lib_mod);
    release_safe_mod.addImport("build_options", build_options.createModule());

    const release_safe_exe = b.addExecutable(.{
        .name = "fasten-safe",
        .root_module = release_safe_mod,
    });
    const release_safe_step = b.step("release-safe", "Build optimized version with safety checks");
    release_safe_step.dependOn(&b.addInstallArtifact(release_safe_exe, .{}).step);

    const release_fast_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    release_fast_mod.addImport("fasten_lib", lib_mod);
    release_fast_mod.addImport("build_options", build_options.createModule());

    const release_fast_exe = b.addExecutable(.{
        .name = "fasten-fast",
        .root_module = release_fast_mod,
    });
    const release_fast_step = b.step("release-fast", "Build fastest optimized version");
    release_fast_step.dependOn(&b.addInstallArtifact(release_fast_exe, .{}).step);
}
