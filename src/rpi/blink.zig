const std = @import("std");
const c = @cImport({
    @cInclude("wiringPi.h");
});

const LED: c_uint = 7;

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

const ISM_IMU: c_uint = 0x6a;
var ISM_IMU_FILE: c_int = null;
pub fn init_ism_imu() !c_int {
    const res: c_int = c.wiringPiI2CSetup(ISM_IMU);
    if (res != 0) {
        std.log.err("init_ism_imu() FAILED with code {d}", .{res});
        return error.InitIsmImu;
    }
}

pub fn setup() !void {
    const res: c_int = c.wiringPiSetup();
    if (res != 0) {
        std.log.err("wriingPiSetup() FAILED with code {d}", .{res});
        return error.WiringPiSetup;
    }

    c.pinMode(LED, c.OUTPUT);
}

pub fn update_io() void {
    c.digitalWrite(LED, c.HIGH);
    c.delay(500);
    c.digitalWrite(LED, c.LOW);
    c.delay(500);
}
