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
    // ism330dlc.calibrate(1000);

    c.pinMode(LED, c.OUTPUT);
}

pub fn update_io() void {
    const reading: ism330dlc.ImuReading = ism330dlc.read();
    buffer.write_float(.gryo_x, reading.gx);
    buffer.write_float(.gryo_y, reading.gy);
    buffer.write_float(.gryo_z, reading.gz);
    buffer.write_float(.accel_x, reading.ax);
    buffer.write_float(.accel_y, reading.ay);
    buffer.write_float(.accel_z, reading.az);
}
