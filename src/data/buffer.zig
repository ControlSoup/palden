const std = @import("std");
const logger = @import("logger.zig");
const fba = @import("../fba.zig");

// =================================================
// Buffers
// =================================================
// Each buffer publically exposes indexs and read / write
// methods, it does not expose data or metadata directly

pub const UINT_IDXS = enum(usize) {
    time,
    dt,
};

pub const INT_IDXS = enum(usize) {
    cycle_count,
};

pub const FLOAT_IDXS = enum(usize) {
    accel_x,
    accel_y,
    accel_z,
    gryo_x,
    gryo_y,
    gryo_z,
};

var uints_data = [1]u64{0.0} ** std.meta.fields(UINT_IDXS).len;
var ints_data = [1]i32{0.0} ** std.meta.fields(INT_IDXS).len;
var floats_data = [1]f32{0.0} ** std.meta.fields(FLOAT_IDXS).len;

pub fn read_uint(idx: UINT_IDXS) u64 {
    return uints_data[@intFromEnum(idx)];
}

pub fn write_uint(idx: UINT_IDXS, val: u64) void {
    uints_data[@intFromEnum(idx)] = val;
}

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

    var values: []u8 = try std.fmt.allocPrint(allocator, "{s}", .{std.meta.fields(UINT_IDXS)[0].name});

    inline for (std.meta.fields(UINT_IDXS)[1..]) |f| {
        values = try std.fmt.allocPrint(allocator, "{s},{s}", .{ values, f.name });
    }

    inline for (std.meta.fields(INT_IDXS)) |f| {
        values = try std.fmt.allocPrint(allocator, "{s},{s}", .{ values, f.name });
    }

    inline for (std.meta.fields(FLOAT_IDXS), 0..) |f, i| {
        if (i < std.meta.fields(FLOAT_IDXS).len - 1) {
            values = try std.fmt.allocPrint(allocator, "{s},{s}", .{ values, f.name });
        } else {
            values = try std.fmt.allocPrint(allocator, "{s}\n", .{values});
        }
    }
    try logger.write_line(values);
}

pub fn record() !void {
    if (!logger.is_recording()) {
        try logger.start_recording();
        try write_header();
    }

    var pre_allocated = std.heap.FixedBufferAllocator.init(&fba.pre_allocated_data);
    const allocator = pre_allocated.allocator();

    var values: []u8 = try std.fmt.allocPrint(allocator, "{d}", .{uints_data[std.meta.fields(UINT_IDXS)[0].value]});

    inline for (std.meta.fields(UINT_IDXS)[1..]) |uint| {
        values = try std.fmt.allocPrint(allocator, "{s},{d}", .{ values, uints_data[uint.value] });
    }
    inline for (std.meta.fields(INT_IDXS)) |int| {
        values = try std.fmt.allocPrint(allocator, "{s},{d}", .{ values, ints_data[int.value] });
    }
    inline for (std.meta.fields(FLOAT_IDXS), 0..) |float, i| {
        if (i < std.meta.fields(FLOAT_IDXS).len - 1) {
            values = try std.fmt.allocPrint(allocator, "{s},{e}", .{ values, floats_data[float.value] });
        } else {
            values = try std.fmt.allocPrint(allocator, "{s}\n", .{values});
        }
    }
    try logger.write_line(values);

    // Fixed buffer will free when out of scope
}

pub fn buffer_stop_recording() !void {
    try logger.stop_recording();
}
