const std = @import("std");
const c = @cImport({
    @cInclude("limits.h");
    @cInclude("wiringPi.h");
    @cInclude("wiringPiI2C.h");
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

const ISM_IMU: c_int = 0x6a;

// Accelerometer Settings (4g)
const ISM_ACCEL_CTRL1_XL: c_int = 0x10;
const ISM_ACCEL_CTRL1_XL_SET: c_int = 0b10101000;

// Accelerometer Read
const ISM_ACCEL_OUTX_L_A: c_int = 0x28;
const ISM_ACCEL_OUTY_L_A: c_int = 0x2A;
const ISM_ACCEL_OUTZ_L_A: c_int = 0x2C;

// Gyroscope Settings (500dps)
const ISM_GRYO_CTRL2_G: c_int = 0x11;
const ISM_GRYO_CTRL2_G_SET: c_int = 0b10100001;

// GRYO Scope Read
const ISM_GRYO_OUTX_L_G: c_int = 0x22;
const ISM_GRYO_OUTY_L_G: c_int = 0x24;
const ISM_GRYO_OUTZ_L_G: c_int = 0x26;

var ISM_IMU_FILE: c_int = c.INT_MAX;
fn init_ism_imu() !void {
    var res: c_int = c.wiringPiI2CSetup(ISM_IMU);
    if (res < 0) {
        std.log.err("init_ism_imu() FAILED with code {d}", .{res});
        return error.InitIsmImu;
    }

    ISM_IMU_FILE = res;

    res = c.wiringPiI2CWriteReg8(ISM_IMU_FILE, ISM_ACCEL_CTRL1_XL, ISM_ACCEL_CTRL1_XL_SET);
    if (res != 0) {
        std.log.err("init_ism_imu() failed to write CTRL1_XL (ACCEL) got code {d} from i2c_smbusaccess", .{res});
        return error.InitIsmImu;
    }

    res = c.wiringPiI2CWriteReg8(ISM_IMU_FILE, ISM_GRYO_CTRL2_G, ISM_GRYO_CTRL2_G_SET);
    if (res != 0) {
        std.log.err("init_ism_imu() failed to write CTRL2_G (GRYO) got code {d} from i2c_smbusaccess", .{res});
        return error.InitIsmImu;
    }
}

pub fn setup() !void {
    const res: c_int = c.wiringPiSetup();
    if (res != 0) {
        std.log.err("wriingPiSetup() FAILED with code {d}", .{res});
        return error.WiringPiSetup;
    }

    try init_ism_imu();

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
        const lsb_gx: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_GRYO_OUTX_L_G);
        const lsb_gy: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_GRYO_OUTY_L_G);
        const lsb_gz: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_GRYO_OUTZ_L_G);
        const lsb_ax: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_ACCEL_OUTX_L_A);
        const lsb_ay: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_ACCEL_OUTY_L_A);
        const lsb_az: c_int = c.wiringPiI2CReadReg16(ISM_IMU_FILE, ISM_ACCEL_OUTZ_L_A);

        const gx = @as(f32, @floatFromInt(lsb_gx)) * 0.00875;
        const gy = @as(f32, @floatFromInt(lsb_gy)) * 0.00875;
        const gz = @as(f32, @floatFromInt(lsb_gz)) * 0.00875;
        const ax = @as(f32, @floatFromInt(lsb_ax)) * 0.000122;
        const ay = @as(f32, @floatFromInt(lsb_ay)) * 0.000122;
        const az = @as(f32, @floatFromInt(lsb_az)) * 0.000122;

        gx_avg += gx;
        gy_avg += gy;
        gz_avg += gz;
        ax_avg += ax;
        ay_avg += ay;
        az_avg += az;
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
