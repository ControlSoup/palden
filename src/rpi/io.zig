const std = @import("std");
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
    ism330dlc.calibrate(1000);

    c.pinMode(LED, c.OUTPUT);
}

pub fn update_io() void {
    var gx_avg: f32 = 0.0;
    var gy_avg: f32 = 0.0;
    var gz_avg: f32 = 0.0;
    var ax_avg: f32 = 0.0;
    var ay_avg: f32 = 0.0;
    var az_avg: f32 = 0.0;

    const n: u8 = 100;
    for (0..n) |_| {
        const reading: ism330dlc.ImuReading = ism330dlc.read();
        gx_avg += reading.gx;
        gy_avg += reading.gy;
        gz_avg += reading.gz;

        ax_avg += reading.ax;
        ay_avg += reading.ay;
        az_avg += reading.az;
    }
    gx_avg = gx_avg / 100.0;
    gy_avg = gy_avg / 100.0;
    gz_avg = gz_avg / 100.0;
    ax_avg = ax_avg / 100.0;
    ay_avg = ay_avg / 100.0;
    az_avg = az_avg / 100.0;

    std.log.info("Raw Gx: {d}, Gy: {d}, Gz: {d}, Ax: {d}, Ay: {d}, Az: {d}", .{ gx_avg, gy_avg, gz_avg, ax_avg, ay_avg, az_avg });
    c.delay(5);
}
