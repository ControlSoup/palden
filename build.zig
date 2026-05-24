const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .gnu,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "palden",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.link_libc = true;
    exe.root_module.addIncludePath(.{ .cwd_relative = "/home/jowilson/palden_sshfs/mount/usr/include" });
    exe.root_module.addLibraryPath(.{ .cwd_relative = "." });
    exe.root_module.linkSystemLibrary("wiringPi", .{});

    b.installArtifact(exe);
}
