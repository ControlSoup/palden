const std = @import("std");
const logger = @import("logger.zig");

var time: u64 = 0;
pub fn write_time(value: u64) void {
    time = value;
}
pub fn read_time() u64 {
    return time;
}

pub const INT_IDXS = enum(usize) {
    cycle_count,
};
const INT_IDXS_FIELDS = std.meta.fields(FLOAT_IDXS);

var int_data = [1]i32{0.0} ** @typeInfo(INT_IDXS).@"enum".fields.len;

pub fn write_int(idx: INT_IDXS, value: i32) void {
    int_data[@intFromEnum(idx)] = value;
}

pub fn read_int(idx: INT_IDXS) i32 {
    return int_data[@intFromEnum(idx)];
}

pub const FLOAT_IDXS = enum(usize) {
    accel_x,
    accel_y,
    accel_z,
    gryo_x,
    gryo_y,
    gryo_z,
};
const FLOAT_IDX_FIELDS = std.meta.fields(FLOAT_IDXS);
var float_data = [1]f32{0.0} ** @typeInfo(FLOAT_IDXS).@"enum".fields.len;

pub fn write_float(idx: FLOAT_IDXS, value: f32) void {
    float_data[@intFromEnum(idx)] = value;
}

pub fn read_float(idx: FLOAT_IDXS) f32 {
    return float_data[@intFromEnum(idx)];
}

pub fn record() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    if (!logger.is_recording()) {
        try logger.start_recording();

        var header: []const u8 = "time";

        inline for (INT_IDXS_FIELDS) |f| {
            header = try std.fmt.allocPrint(
                allocator,
                "{s},{s}",
                .{ header, f.name },
            );
        }
        inline for (FLOAT_IDX_FIELDS) |f| {
            header = try std.fmt.allocPrint(
                allocator,
                "{s},{s}",
                .{ header, f.name },
            );
        }
        try logger.write_line(try std.fmt.allocPrint(allocator, "{s}\n", .{header}));
    }

    var values: []u8 = try std.fmt.allocPrint(allocator, "{d}", .{time});
    for (int_data) |int| {
        values = try std.fmt.allocPrint(allocator, "{s},{d}", .{ values, int });
    }
    for (float_data) |float| {
        values = try std.fmt.allocPrint(allocator, "{s},{d}", .{ values, float });
    }
    try logger.write_line(try std.fmt.allocPrint(allocator, "{s}\n", .{values}));
}

pub fn buffer_stop_recording() !void {
    try logger.stop_recording();
}
