const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = std.zig.CrossTarget {
        .cpu_arch = std.Target.Cpu.Arch.mips64el,
        .cpu_model =  std.zig.CrossTarget.CpuModel {
          .explicit = &std.Target.mips.cpu.mips3
        },
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.gnuabin32
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Fake libraries to workaround zig's `libcFullLinkFlags`
    inline for (.{"dl", "rt", "util"}) |x| {
        const lib = b.addStaticLibrary(x, "src/empty.c");
        lib.setTarget(target);
        lib.setBuildMode(mode);
        lib.install();
    }

    var exe = b.addExecutable("ps2.elf", "src/main.c");
    exe.force_pic = false;
    exe.pie = false;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.setLibCFile(std.build.FileSource.relative("./out.txt"));
    exe.defineCMacro("_EE", null);
    // exe.addIncludePath("/usr/local/ps2dev/ee/mips64r5900el-ps2-elf/include");
    exe.addIncludePath("/usr/local/ps2dev/ps2sdk/common/include");
    exe.addIncludePath("/usr/local/ps2dev/gsKit/include");
    exe.addLibraryPath("/usr/local/ps2dev/gsKit/lib");
    exe.addLibraryPath("./zig-out/lib");
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
