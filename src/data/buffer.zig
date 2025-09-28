const std = @import("std");
const logger = @import("logger.zig");
const buffer = @import("../data/buffer.zig");
const fba = @import("../fba.zig");

// =================================================
// Buffers
// =================================================
// Each buffer publically exposes indexs and read / write
// methods, it does not expose data or metadata directly

pub const INT_IDXS = enum(usize) {
    cycle_count,
    gryo_x_lsb,
    accel_z_lsb,
};

pub const FLOAT_IDXS = enum(usize) {
    time,
    dt, // f32 maybe to small for this??? probably not :)
    accel_x,
    accel_y,
    accel_z,
    gryo_x,
    gryo_y,
    gryo_z,
    servo,
};

var ints_data = [1]i32{0.0} ** std.meta.fields(INT_IDXS).len;
var floats_data = [1]f32{0.0} ** std.meta.fields(FLOAT_IDXS).len;

pub fn read_int(idx: INT_IDXS) i32 {
    return ints_data[@intFromEnum(idx)];
}

pub fn write_int(idx: INT_IDXS, val: i32) void {
    ints_data[@intFromEnum(idx)] = val;
}

pub fn read_float(idx: FLOAT_IDXS) f32 {
    return floats_data[@intFromEnum(idx)];
}

pub fn write_float(idx: FLOAT_IDXS, val: f32) void {
    floats_data[@intFromEnum(idx)] = val;
}

// =================================================
// Logging
// =================================================

// Header does not change, probably could just do this once at comptime???
pub fn write_header() !void {
    var pre_allocated = std.heap.FixedBufferAllocator.init(&fba.pre_allocated_data);
    const allocator = pre_allocated.allocator();

    var values: []u8 = try std.fmt.allocPrint(allocator, "{s}", .{std.meta.fields(INT_IDXS)[0].name});

    inline for (std.meta.fields(INT_IDXS)[1..]) |f| {
        values = try std.fmt.allocPrint(allocator, "{s},{s}", .{ values, f.name });
    }

    inline for (std.meta.fields(FLOAT_IDXS)) |f| {
        values = try std.fmt.allocPrint(allocator, "{s},{s}", .{ values, f.name });
    }
    values = try std.fmt.allocPrint(allocator, "{s}\n", .{values});
    try logger.write_line(values);
}

pub fn record() !void {
    if (!logger.is_recording()) {
        try logger.start_recording();
        try write_header();
    }

    var pre_allocated = std.heap.FixedBufferAllocator.init(&fba.pre_allocated_data);
    const allocator = pre_allocated.allocator();

    var values: []u8 = try std.fmt.allocPrint(allocator, "{d}", .{ints_data[std.meta.fields(INT_IDXS)[0].value]});

    inline for (std.meta.fields(INT_IDXS)[1..]) |int| {
        values = try std.fmt.allocPrint(allocator, "{s},{d}", .{ values, ints_data[int.value] });
    }

    inline for (std.meta.fields(FLOAT_IDXS)) |float| {
        values = try std.fmt.allocPrint(allocator, "{s},{e}", .{ values, floats_data[float.value] });
    }
    values = try std.fmt.allocPrint(allocator, "{s}\n", .{values});
    try logger.write_line(values);
}

pub fn stop_recording() !void {
    try logger.stop_recording();
}
