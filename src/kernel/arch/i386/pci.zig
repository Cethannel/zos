const std = @import("std");
const x86 = @import("x86.zig");
const serial = @import("serial.zig");

pub fn pciConfigReadWord(bus: u8, slot: u8, func: u8, offset: u8) u16 {
    var address: u32 = undefined;
    const lbus: u32 = @intCast(bus);
    const lslot: u32 = @intCast(slot);
    const lfunc: u32 = @intCast(func);

    address = ((lbus << 16) | (lslot << 11) | (lfunc << 8) | (offset & 0xFC) |
        0x80000000);

    x86.outl(0xCF8, address);

    var tmp: u16 = undefined;

    tmp = @intCast(((x86.inl(0xCFC) >> @intCast(((offset & 2) * 8))) & 0xFFFF));

    return tmp;
}

fn unionType(comptime Union: type, comptime active_field_name: []const u8) type {
    return @TypeOf(@field(@unionInit(Union, active_field_name, undefined), active_field_name));
}

pub fn get_type(comptime t: type, bus: u8, slot: u8, func: u8, offset: u8) t {
    var out: t = undefined;

    const inDataType = [@bitSizeOf(t) / 8 / 2]u16;

    var inData: inDataType = undefined;

    comptime {
        if (@bitSizeOf(inDataType) != @bitSizeOf(t)) {
            @compileError("Wrong sized data");
        }
    }

    for (&inData, 0..) |*value, i| {
        value.* = pciConfigReadWord(bus, slot, func, offset + @as(u8, @intCast(i * 2)));
    }

    out = @bitCast(inData);

    return out;
}

pub const HeaderType = enum(u8) {
    GeneralDevice = 0x0,
    PciPciBridge = 0x1,
    PciPCMCIABridge = 0x2,
    MultiPurpose = 0b01000000,
    Invalid = 0xFF,

    pub fn debug_print(self: *const @This(), indent: usize) void {
        _ = indent;
        const intRep: u8 = @intFromEnum(self.*);
        if (intRep > 0x2) {
            serial.print("MultiPurpose: 0b{b}", .{intRep});
        } else {
            serial.print("{any}", .{self.*});
        }
    }

    pub fn sanitize(self: @This()) @This() {
        const intRep: u8 = @intFromEnum(self);
        if (intRep > 3 and intRep != @intFromEnum(HeaderType.MultiPurpose)) {
            return HeaderType.Invalid;
        }
        return self;
    }
};

pub const CommandRegister = packed struct {
    IOSpace: bool,
    memorySpace: bool,
    busMaster: bool,
    specialCycles: bool,
    memoryWriteAndInvalidateEnable: bool,
    VGAPaletteSnoop: bool,
    parityErrorResponse: bool,
    _reserved0: u1,
    SERRNoEnable: bool,
    fastBackToBackEnable: bool,
    interruptDisable: bool,
    _reserved1: u5,

    comptime {
        if (@sizeOf(@This()) != (@sizeOf(u16))) {
            @compileError("Wrong CommandHeaders size");
        }
    }
};

pub const CommandHeaders = struct {
    pub const CommonHeaders = packed struct {
        vendorId: u16,
        deviceId: u16,
        command: CommandRegister,
        status: u16,
        revisionId: u8,
        progIf: u8,
        subClass: u8,
        classCode: u8,
        cacheLineSize: u8,
        latencyTimer: u8,
        headerType: HeaderType,
        BIST: u8,

        pub fn get(bus: u8, slot: u8) @This() {
            return get_type(@This(), bus, slot, 0, 0);
        }
    };
    pub const Rest = union(HeaderType) {
        GeneralDevice: packed struct {
            BAR0: u32,
            BAR1: u32,
            BAR2: u32,
            BAR3: u32,
            BAR4: u32,
            BAR5: u32,
            cardbusCISPointer: u32,
            subsystemVendorID: u16,
            subsystemID: u16,
            expansionROMBaseAddress: u32,
            capabilitiesPointer: u8,
            _reserved0: u24,
            _reserved1: u32,
            interruptLine: u8,
            interruptPIN: u8,
            minGrant: u8,
            maxLatency: u8,
        },
        PciPciBridge: packed struct {
            BAR0: u32,
            BAR1: u32,
            primaryBusNumber: u8,
            secondaryBusNumber: u8,
            subordinateBusNumber: u8,
            secondaryLatencyTimer: u8,
            IOBase: u8,
            IOLimit: u8,
            secondaryStatus: u16,
            memoryBase: u16,
            memoryLimit: u16,
            prefetchableMemoryBase: u16,
            prefetchableMemoryLimit: u16,
            prefetchableBaseUpper32Bits: u32,
            prefetchableLimitUpper32Bits: u32,
            IOBaseUpper16Bits: u16,
            IOLimitUpper16Bits: u16,
            capabilityPointer: u8,
            _reserved0: u24,
            expansionROMBaseAddress: u32,
            interruptLine: u8,
            interruptPIN: u8,
            bridgeControl: u16,
        },
        PciPCMCIABridge: packed struct {
            cardBusSocket: u32,
            offsetOfCapabilitiesList: u8,
            _reserved0: u8,
            secondaryStatus: u16,
            PCIBusNumber: u8,
            cardBusBusNumber: u8,
            subordinateBusNumber: u8,
            cardBusLatencyTimer: u8,
            memoryBaseAddress0: u32,
            memoryLimit0: u32,
            memoryBaseAddress1: u32,
            memoryLimit1: u32,
            IOBaseAddress0: u32,
            IOLimit0: u32,
            IOBaseAddress1: u32,
            IOLimit1: u32,
            interruptLine: u8,
            interruptPIN: u8,
            bridgeControl: u16,
            subsystemDeviceID: u16,
            subsystemVendorID: u16,
            @"16BitPCCardLegacyModeBaseAddress": u32,
        },
        MultiPurpose: u8,
        Invalid: void,
    };
    commonHeaders: CommonHeaders,
    rest: Rest,

    pub fn get(bus: u8, slot: u8) @This() {
        var out: @This() = undefined;

        out.commonHeaders = CommonHeaders.get(bus, slot);

        switch (out.commonHeaders.headerType.sanitize()) {
            .GeneralDevice => {
                out.rest = .{ .GeneralDevice = get_type(unionType(Rest, "GeneralDevice"), bus, slot, 0, 0x10) };
            },
            .PciPciBridge => {
                out.rest = .{ .PciPciBridge = get_type(unionType(Rest, "PciPciBridge"), bus, slot, 0, 0x10) };
            },
            .PciPCMCIABridge => {
                out.rest = .{ .PciPCMCIABridge = get_type(unionType(Rest, "PciPCMCIABridge"), bus, slot, 0, 0x10) };
            },
            .MultiPurpose => {
                out.rest = .{ .MultiPurpose = @intFromEnum(out.commonHeaders.headerType) };
            },
            .Invalid => {
                out.rest = .Invalid;
            },
        }

        return out;
    }

    pub fn is_valid(self: *const @This()) bool {
        return self.commonHeaders.vendorId != 0xFFFF;
    }

    pub fn getDevice(self: *const @This()) ?Device {
        for (device_list.items) |vendor| {
            if (vendor.id == self.commonHeaders.vendorId) {
                for (vendor.devices.items) |device| {
                    if (device.id == self.commonHeaders.deviceId) {
                        return device;
                    }
                }
            }
        }
        return null;
    }
};

const Vendor = struct {
    id: u16,
    name: []const u8,
    devices: std.ArrayList(Device),
};

const Device = struct {
    id: u16,
    name: []const u8,
};

const PciFileReaderCtx = struct {
    const file = @embedFile("pci.ids");
    const errorSet = error{};
    pos: usize,

    pub fn readFn(self: *@This(), buffer: []u8) errorSet!usize {
        const toRead = @min(file.len - self.pos, buffer.len);

        for (0..toRead) |i| {
            buffer[i] = file[self.pos + i];
        }

        self.pos += toRead;

        return toRead;
    }

    pub fn getReader() type {
        return std.io.Reader(*@This(), errorSet, readFn);
    }

    pub fn init() @This() {
        return .{
            .pos = 0,
        };
    }

    pub fn reader(self: *@This()) getReader() {
        return .{
            .context = self,
        };
    }
};

const device_list = getPCIDeviceList() catch unreachable;

fn errorToOptional(input: anytype) ?@typeInfo(@TypeOf(input)).ErrorUnion.payload {
    return input catch null;
}

fn getPCIDeviceList() !std.ArrayList(Vendor) {
    @setEvalBranchQuota(1000 * 1000);

    var ctx = PciFileReaderCtx.init();
    var reader = ctx.reader();
    const alloc = std.heap.page_allocator;
    var vendors = std.ArrayList(Vendor).init(alloc);
    var vendor: ?Vendor = null;
    var devices = std.ArrayList(Device).init(alloc);

    var deviceIndent = false;

    var lineBuf: [256]u8 = undefined;
    while (errorToOptional(reader.readUntilDelimiter(
        &lineBuf,
        '\n',
    ))) |line| {
        if (line.len == 0) {
            continue;
        }
        if (line[0] == '#' or (line.len >= 3 and line[2] == '\t')) {
            continue;
        }

        if (line[0] == '\t') {
            deviceIndent = true;
        } else {
            deviceIndent = false;
        }

        if (deviceIndent) {
            const id = line[1..5];
            const nameIn = line[7..];
            const name = try alloc.alloc(u8, nameIn.len);
            @memcpy(&name, nameIn);

            const idNum = try std.fmt.parseInt(u16, id, 16);
            devices.append(.{
                .id = idNum,
                .name = name,
            });
        } else {
            if (vendor) |vend| {
                vend.devices = devices;
                try vendors.append(vend);
            }

            const id = line[0..4];
            const nameIn = line[6..];
            const name = try alloc.alloc(u8, nameIn.len);
            @memcpy(&name, nameIn);

            const idNum = try std.fmt.parseInt(u16, id, 16);
            vendor = Vendor{
                .id = idNum,
                .name = name,
                .devices = undefined,
            };
            devices.clearAndFree();
        }
    }
}
