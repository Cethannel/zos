const std = @import("std");
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;

const x86_64 = CrossTarget{
    .cpu_arch = Target.Cpu.Arch.x86,
    .os_tag = .freestanding,
    .cpu_model = .{ .explicit = &Target.x86.cpu.i386 },
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.resolveTargetQuery(x86_64);

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "zig-os",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .use_lld = true,
        .strip = false,
        .link_libc = false,
        .pic = false,
        .code_model = switch (target.result.cpu.arch) {
            .x86_64 => .large,
            .x86 => .default,
            else => @panic(
                b.fmt("Unsupported arch: {s}", .{@tagName(target.result.cpu.arch)}),
            ),
        },
    });

    //kernel.code_model = .kernel;

    const archAsmFiles = [_][]const u8{
        "gdt.S",
        "interrupts.S",
        "util.S",
        "boot.S",
    };

    const archPath = switch (target.query.cpu_arch.?) {
        .x86 => b.path("src/kernel/arch/i386/"),
        .x86_64 => b.path("src/kernel/arch/amd64/"),
        else => @panic(
            b.fmt("Unsupported arch: {s}", .{@tagName(target.result.cpu.arch)}),
        ),
    };

    for (archAsmFiles) |file| {
        kernel.addAssemblyFile(archPath.path(b, file));
    }

    const archObjectFiles = [_][]const u8{
        "isr.o",
    };

    for (archObjectFiles) |file| {
        kernel.addObjectFile(archPath.path(b, file));
    }

    //kernel.addAssemblyFile(b.path("src/kernel/arch/i386/isr.S"));
    //kernel.addObjectFile(b.path("src/kernel/arch/i386/isr.o"));

    const archCFiles = [_][]const u8{
        "memory.c",
    };

    for (archCFiles) |file| {
        kernel.addCSourceFile(.{ .file = archPath.path(b, file) });
    }

    kernel.setLinkerScript(archPath.path(b, "linker.ld"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(kernel);

    var isodir = b.step("isodir", "Make files in isodir");
    isodir.makeFn = makeDirs;

    var grub = b.step("grub", "Adds grub config into dir");
    grub.dependOn(isodir);
    grub.makeFn = copyGrub;

    var osbin = b.step("osbin", "Moves binary to correct spot");
    osbin.dependOn(isodir);
    osbin.dependOn(&kernel.step);
    osbin.makeFn = copyBin;

    const gb = b.option([]const u8, "grub", "grub command to use");

    var grubCmd: []const u8 = "grub-mkrescue";
    if (gb) |gbC| {
        grubCmd = gbC;
    }

    var mkiso = b.addSystemCommand(
        &.{ grubCmd, "--modules=fat" },
    );
    _ = mkiso.captureStdErr();
    mkiso.addArg("-o");
    const iso = mkiso.addOutputFileArg("myos.iso");
    mkiso.addDirectoryArg(b.path(".zig-cache/isodir"));
    mkiso.step.dependOn(&kernel.step);
    mkiso.step.dependOn(grub);
    mkiso.step.dependOn(osbin);

    const outIso = b.addInstallBinFile(iso, "myos.iso");
    outIso.step.dependOn(&mkiso.step);

    b.default_step = &outIso.step;

    const bochsSysCmdOpt = b.option([]const u8, "bochs", "bochs command to use");

    var bochsSysCmd: []const u8 = "bochs";
    if (bochsSysCmdOpt) |bsc| {
        bochsSysCmd = bsc;
    }

    const bochsCmd = b.addSystemCommand(&.{ bochsSysCmd, "-q" });
    bochsCmd.step.dependOn(&mkiso.step);

    const bochsRun = b.step("bochs", "Run bochs");
    bochsRun.dependOn(&bochsCmd.step);

    const qemu = "qemu-system-x86_64";
    const qemuArgs = .{
        "-audiodev",
        "alsa,id=speaker",
        "-machine",
        "pcspk-audiodev=speaker",
    };
    var qemuCmd = b.addSystemCommand(&.{qemu});
    qemuCmd.addFileArg(iso);
    qemuCmd.addArgs(&qemuArgs);
    qemuCmd.step.dependOn(&mkiso.step);

    const qemuRun = b.step("qemu", "Run qemu");
    qemuRun.dependOn(&qemuCmd.step);

    var debugCmd = b.addSystemCommand(&.{qemu});
    debugCmd.addFileArg(iso);
    debugCmd.addArgs(&qemuArgs);
    debugCmd.addArgs(&.{
        "-S",
        "-s",
    });
    debugCmd.step.dependOn(&mkiso.step);

    const debugRun = b.step("debug", "Run qemu");
    debugRun.dependOn(&debugCmd.step);

    var lldb_cmd = b.addSystemCommand(&.{"lldb"});
    lldb_cmd.addArgs(&.{
        "zig-out/bin/myos.iso",
        "--one-line",
        "gdb-remote 1234",
    });
    lldb_cmd.step.dependOn(&mkiso.step);
    lldb_cmd.step.dependOn(&kernel.step);

    const lldbRun = b.step("lldb", "Starts lldb and connects");
    lldbRun.dependOn(&lldb_cmd.step);
}

fn makeDirs(
    step: *std.Build.Step,
    prog_node: std.Progress.Node,
) !void {
    _ = prog_node;
    try step.owner.cache_root.handle.makePath("isodir/boot/grub/");
}

fn copyGrub(
    step: *std.Build.Step,
    prog_node: std.Progress.Node,
) !void {
    _ = prog_node;
    const cache_root = step.owner.cache_root.handle;
    const root = step.owner.build_root.handle;

    var inFile = try root.openFile("grub.cfg", .{ .mode = .read_only });
    defer inFile.close();

    var outDir = try cache_root.createFile("isodir/boot/grub/grub.cfg", .{});
    defer outDir.close();

    try copyFile(&inFile, &outDir);
}

fn copyBin(
    step: *std.Build.Step,
    prog_node: std.Progress.Node,
) !void {
    _ = prog_node;
    const installed_files = step.owner.install_path;
    const cache_root = step.owner.cache_root.handle;

    var install_path = try std.fs.openDirAbsolute(installed_files, .{});

    var inFile = try install_path.openFile("bin/zig-os", .{ .mode = .read_only });
    defer inFile.close();
    var outFile = try cache_root.createFile("isodir/boot/myos.bin", .{});
    defer outFile.close();

    try copyFile(&inFile, &outFile);
}

fn copyFile(inFile: *std.fs.File, outFile: *std.fs.File) !void {
    var buf = [_]u8{0} ** (1024 * 1024);

    const end = try inFile.getEndPos();

    while (try inFile.getPos() < end) {
        const numBytes = try inFile.read(&buf);
        _ = try outFile.write(buf[0..numBytes]);
    }
}
