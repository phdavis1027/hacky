const std = @import("std");

// This entire strategy for processing system includes is ripped from [here](https://github.com/sphaerophoria/sphimp/commit/5754203cb03aaea7da9c92ec8906cb0a723ddb1d#diff-be24616f127a52cfe7e46abecc33047a4d9e6b784a4c8742a029bc5167fff47e)
const process_include_paths = @import("src/build/process_include_paths.zig");

const TranslationModule = struct {
    name: []const u8,
    step: *std.Build.Step.TranslateC
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libxml2_translate = b.addTranslateC(.{
        .root_source_file = b.path("include/libxml2.h"),
        .target = target,
        .optimize = optimize,
    });

    const libavahi_client_translate = b.addTranslateC(.{
        .root_source_file = b.path("include/avahi.h"),
        .target = target,
        .optimize = optimize,
    });

    const translations = [_] *std.Build.Step.TranslateC {
        libxml2_translate, libavahi_client_translate
    };

    var include_it = try process_include_paths.IncludeIter.init(b.allocator);
    while (include_it.next()) |p| {
        std.debug.print("[INFO] processing include: {s}\n", .{p});
        for (translations) |trans| {
            trans.addSystemIncludePath(std.Build.LazyPath{ .cwd_relative = p });
        }
    }

    const root_module = b.addModule("hacky", .{ .target = target, .optimize = optimize, .link_libc = true, .root_source_file = b.path("src/hacky.zig") });

    const mods = [_] TranslationModule {
        .{ .name = "xml2", .step = libxml2_translate },
        .{ .name = "avahi-client", .step= libavahi_client_translate }
    };

    for (mods) |mod| {
        const tmp = mod.step.createModule();
        tmp.linkSystemLibrary(mod.name, .{});

        root_module.addImport(mod.name, mod.step.createModule());
        root_module.linkSystemLibrary(mod.name, .{});
    }

    const libhacky = b.addLibrary(.{ .name = "hacky", .linkage = .dynamic, .root_module = root_module });

    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that don't match the filter") orelse &[0][]const u8{};
    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{ .root_module = root_module, .target = target, .optimize = optimize, .filters = test_filters });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    b.installArtifact(libhacky);
}
