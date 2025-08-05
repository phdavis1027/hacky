const std = @import("std");

// This entire strategy for processing system includes is ripped from [here](https://github.com/sphaerophoria/sphimp/commit/5754203cb03aaea7da9c92ec8906cb0a723ddb1d#diff-be24616f127a52cfe7e46abecc33047a4d9e6b784a4c8742a029bc5167fff47e)
const process_include_paths = @import("src/build/process_include_paths.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libxml2_translate = b.addTranslateC(.{
        .root_source_file = b.path("include/libxml2.h"),
        .target = target,
        .optimize = optimize,
    });

    var include_it = try process_include_paths.IncludeIter.init(b.allocator);
    while (include_it.next()) |p| {
        std.debug.print("[INFO] processing include: {s}\n", .{p});
        libxml2_translate.addSystemIncludePath(std.Build.LazyPath{ .cwd_relative = p });
    }

    const libxml2_translate_mod = libxml2_translate.createModule();
    libxml2_translate_mod.linkSystemLibrary("xml2", .{});

    const root_module = b.addModule("hacky", .{ .target = target, .optimize = optimize, .link_libc = true, .root_source_file = b.path("src/hacky.zig") });
    root_module.addImport("xml", libxml2_translate.createModule());
    root_module.linkSystemLibrary("xml2", .{});

    const libhacky = b.addLibrary(.{ .name = "hacky", .linkage = .dynamic, .root_module = root_module });

    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that don't match the filter") orelse &[0][]const u8{};
    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{ .root_module = root_module, .target = target, .optimize = optimize, .filters = test_filters });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    b.installArtifact(libhacky);
}
