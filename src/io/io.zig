const std = @import("std");
const buffer = @import("../data/buffer.zig");
pub const ism330dlc = @import("ism330dlc.zig");
const c = @cImport({
    @cInclude("limits.h");
    @cInclude("wiringPi.h");
    @cInclude("softPwm.h");
    @cInclude("wiringPiI2C.h");
});

const LED: c_uint = 7;
const PWM: c_uint = 26;
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
    var res: c_int = c.wiringPiSetup();
    if (res != 0) {
        std.log.err("wiringPiSetup() FAILED with code {d}", .{res});
        return error.WiringPiSetup;
    }

    try ism330dlc.init_ism_imu(IMU);
    try ism330dlc.log_settings();
    ism330dlc.calibrate(500);

    c.pinMode(LED, c.OUTPUT);
    res = c.softPwmCreate(PWM, 0, 100);
    if (res != 0) {
        std.log.err("Unable to create a software PWM on pin {d}", .{PWM});
    }
}

pub fn frac_to_servo(frac: f32) c_int {
    const command = @min(@max(frac, 0.0), 1.0) * 100;
    return @as(c_int, @intFromFloat(command));
}

// NOTE: Runs once per event cycle
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
    c.softPwmWrite(PWM, frac_to_servo(buffer.read_float(.servo)));
}
