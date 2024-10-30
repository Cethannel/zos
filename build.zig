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
    });

    //kernel.code_model = .kernel;

    kernel.addAssemblyFile(b.path("src/boot.S"));
    kernel.addAssemblyFile(b.path("src/kernel/arch/i386/gdt.S"));
    kernel.addAssemblyFile(b.path("src/kernel/arch/i386/interrupts.S"));
    kernel.addAssemblyFile(b.path("src/kernel/arch/i386/util.S"));
    //kernel.addAssemblyFile(b.path("src/kernel/arch/i386/isr.S"));
    kernel.addObjectFile(b.path("src/kernel/arch/i386/isr.o"));
    kernel.addCSourceFile(.{
        .file = b.path("src/kernel/arch/i386/memory.c"),
    });

    kernel.setLinkerScript(b.path("src/linker.ld"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(kernel);
}
