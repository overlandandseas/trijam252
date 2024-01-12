const std = @import("std");
const fs = std.fs;
const raylib_sdk = @import("ext/raylib/src/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const options = .{
        .name = "trijam252",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    };
    if (target.query.cpu_arch != .wasm32) {
        nativeBuild(b, options);
    } else {
        try wasmBuild(b, options);
    }
}

fn wasmBuild(b: *std.Build, options: std.Build.StaticLibraryOptions) !void {
    const raylib = raylib_sdk.addRaylib(b, options.target, options.optimize, .{});
    const cflags = [_][]const u8{
        "-D RAYGUI_IMPLEMENTATION",
        "-Iext/raylib/zig-out/include",
        // "-Lext/raylib/zig-out/lib",
        // "-lraylib",
    };

    const lib = b.addStaticLibrary(options);
    lib.addCSourceFile(.{
        .file = .{
            .path = "ext/raylib/src/raygui.c",
        },
        .flags = &cflags,
    });
    lib.addIncludePath(.{ .path = "/opt/homebrew/Cellar/emscripten/3.1.51/libexec/cache/sysroot/include" });
    lib.addIncludePath(.{ .path = "ext/raylib/src" });
    lib.linkLibrary(raylib);

    b.installArtifact(lib);
    b.installArtifact(raylib);

    const emcc_path = try fs.path.join(b.allocator, &.{ b.sysroot.?, "emcc" });
    defer b.allocator.free(emcc_path);
    try fs.cwd().makePath("zig-out/web");

    const emcc = b.addSystemCommand(&.{ emcc_path, "-ozig-out/web/index.html", "zig-out/lib/libtrijam252.a", "zig-out/lib/libraylib.a", "-sASYNCIFY", "-sUSE_GLFW=3", "-sGL_ENABLE_GET_PROC_ADDRESS", "-DPLATFORM_WEB", "--shell-file", "minshell", "--preload-file", "res" });

    emcc.step.dependOn(&lib.step);

    b.getInstallStep().dependOn(&emcc.step);
}

fn nativeBuild(b: *std.Build, options: std.Build.ExecutableOptions) void {
    const raylib = raylib_sdk.addRaylib(b, options.target, options.optimize, .{});
    const cflags = [_][]const u8{
        "-D RAYGUI_IMPLEMENTATION",
        "-Iext/raylib/zig-out/include",
        "-Lext/raylib/zig-out/lib",
        "-lraylib",
    };
    const exe = b.addExecutable(options);
    exe.addCSourceFile(.{
        .file = .{
            .path = "ext/raylib/src/raygui.c",
        },
        .flags = &cflags,
    });

    exe.addIncludePath(.{ .path = "ext/raylib/src" });
    exe.linkLibrary(raylib);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
