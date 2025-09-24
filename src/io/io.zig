const std = @import("std");
const buffer = @import("../data/buffer.zig");
pub const ism330dlc = @import("ism330dlc.zig");
const c = @cImport({
    @cInclude("limits.h");
    @cInclude("wiringPi.h");
    @cInclude("wiringPiI2C.h");
});

const LED: c_uint = 7;
const IMU: c_int = 0x6a;

//      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
// 00:                         -- -- -- -- -- -- -- --
// 10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
// 20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
// 30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
// 40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
// 50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
// 60: -- -- -- -- -- -- -- -- -- -- 6a -- -- -- -- --
// 70: -- -- -- -- -- -- -- --
//

pub fn setup() !void {
    const res: c_int = c.wiringPiSetup();
    if (res != 0) {
        std.log.err("wriingPiSetup() FAILED with code {d}", .{res});
        return error.WiringPiSetup;
    }

    try ism330dlc.init_ism_imu(IMU);
    try ism330dlc.log_settings();
    ism330dlc.calibrate(500);

    c.pinMode(LED, c.OUTPUT);
}

pub fn update_io() void {
    const is = ism330dlc.is_imu_ready();

    // NOTE: ~900hz upper limit
    if (is.accel_ready) {
        const accel = ism330dlc.read_accel();
        buffer.write_float(.accel_x, accel.ax);
        buffer.write_float(.accel_y, accel.ay);
        buffer.write_float(.accel_z, accel.az);
    }

    if (is.gryo_ready) {
        const gryo = ism330dlc.read_gryo();
        buffer.write_float(.gryo_x, gryo.gx);
        buffer.write_float(.gryo_y, gryo.gy);
        buffer.write_float(.gryo_z, gryo.gz);
    }
}
