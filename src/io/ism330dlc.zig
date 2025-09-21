const std = @import("std");
const c = @cImport({
    @cInclude("limits.h");
    @cInclude("wiringPi.h");
    @cInclude("wiringPiI2C.h");
});

var FILE: c_int = undefined;

// Accelerometer Read
const ACCEL_OUTX_L_A: c_int = 0x28;
const ACCEL_OUTY_L_A: c_int = 0x2A;
const ACCEL_OUTZ_L_A: c_int = 0x2C;

// GRYO Scope Read
const GRYO_OUTX_L_G: c_int = 0x22;
const GRYO_OUTY_L_G: c_int = 0x24;
const GRYO_OUTZ_L_G: c_int = 0x26;

const STATUS_REG: c_int = 0x1E;

// Accelerometer Settings (4g) 3.3khz
const ACCEL_CTRL1_XL: c_int = 0x10;
const ACCEL_CTRL1_XL_SET: c_int = 0b10011000;
const ACCEL_LSB_TO_G: f16 = 0.000122;

const ACCEL_X_OFS_USR: c_int = 0x73;
const ACCEL_Y_OFS_USR: c_int = 0x74;
const ACCEL_Z_OFS_USR: c_int = 0x75;

// Gyroscope Settings (250dps) 3.3khz
const GRYO_CTRL2_G: c_int = 0x11;
const GRYO_CTRL2_G_SET: c_int = 0b10010000;
const GRYO_LSB_TO_DEGPS: f16 = 0.00875;

var ACCEL_X_TARE: f32 = 0;
var ACCEL_Y_TARE: f32 = 0;
var ACCEL_Z_TARE: f32 = 0;

var GRYO_X_TARE: f32 = 0;
var GRYO_Y_TARE: f32 = 0;
var GRYO_Z_TARE: f32 = 0;

pub fn init_ism_imu(addr: c_int) !void {
    var res: c_int = c.wiringPiI2CSetup(addr);
    if (res < 0) {
        std.log.err("init_ism_imu() FAILED with code {d}", .{res});
        return error.InitIsmImu;
    }
    FILE = res;

    res = c.wiringPiI2CWriteReg8(FILE, ACCEL_CTRL1_XL, ACCEL_CTRL1_XL_SET);
    if (res != 0) {
        std.log.err("init_ism_imu() failed to write CTRL1_XL (ACCEL) got code {d} from i2c_smbusaccess", .{res});
        return error.InitIsmImu;
    }

    res = c.wiringPiI2CWriteReg8(FILE, GRYO_CTRL2_G, GRYO_CTRL2_G_SET);
    if (res != 0) {
        std.log.err("init_ism_imu() failed to write CTRL2_G (GRYO) got code {d} from i2c_smbusaccess", .{res});
        return error.InitIsmImu;
    }
}

pub fn log_settings() !void {
    var res: c_int = c.wiringPiI2CReadReg8(FILE, ACCEL_CTRL1_XL);
    if (res < 0) {
        std.log.err("init_ism_imu failed to read CTRL1_XL (ACCEL) got code {d} from i2c_smbusacess", .{res});
        return error.InitIsmImu;
    }
    std.log.info("CTRL1_XL (ACCEL): {b}", .{res});
    std.log.info("ACCEL_X_TARE: {d}", .{ACCEL_X_TARE});
    std.log.info("ACCEL_Y_TARE: {d}", .{ACCEL_Y_TARE});
    std.log.info("ACCEL_Z_TARE: {d}", .{ACCEL_Z_TARE});

    res = c.wiringPiI2CReadReg8(FILE, GRYO_CTRL2_G);
    if (res < 0) {
        std.log.err("init_ism_imu failed to read CTR2_G (GRYO) got code {d} from i2c_smbusacess", .{res});
        return error.InitIsmImu;
    }
    std.log.info("CTRL2_G (GRYO): {b}", .{res});
    std.log.info("GRYO_X_TARE: {d}", .{GRYO_X_TARE});
    std.log.info("GRYO_Y_TARE: {d}", .{GRYO_Y_TARE});
    std.log.info("GRYO_Z_TARE: {d}", .{GRYO_Z_TARE});
}

pub fn calibrate(n: u16) void {
    var gx_avg: c_int = 0.0;
    var gy_avg: c_int = 0.0;
    var gz_avg: c_int = 0.0;

    var ax_avg: c_int = 0.0;
    var ay_avg: c_int = 0.0;
    var az_avg: c_int = 0.0;
    for (0..n) |_| {
        gx_avg += c.wiringPiI2CReadReg16(FILE, GRYO_OUTX_L_G);
        gy_avg += c.wiringPiI2CReadReg16(FILE, GRYO_OUTY_L_G);
        gz_avg += c.wiringPiI2CReadReg16(FILE, GRYO_OUTZ_L_G);
        ax_avg += c.wiringPiI2CReadReg16(FILE, ACCEL_OUTX_L_A);
        ay_avg += c.wiringPiI2CReadReg16(FILE, ACCEL_OUTY_L_A);
        az_avg += c.wiringPiI2CReadReg16(FILE, ACCEL_OUTZ_L_A);
    }

    gx_avg = @divTrunc(gx_avg, n);
    gy_avg = @divTrunc(gy_avg, n);
    gz_avg = @divTrunc(gz_avg, n);
    ax_avg = @divTrunc(ax_avg, n);
    ay_avg = @divTrunc(ay_avg, n);
    az_avg = @divTrunc(az_avg, n);

    GRYO_X_TARE = @as(f32, @floatFromInt(gx_avg)) * GRYO_LSB_TO_DEGPS;
    GRYO_Y_TARE = @as(f32, @floatFromInt(gy_avg)) * GRYO_LSB_TO_DEGPS;
    GRYO_Z_TARE = @as(f32, @floatFromInt(gz_avg)) * GRYO_LSB_TO_DEGPS;
    ACCEL_X_TARE = @as(f32, @floatFromInt(ax_avg)) * ACCEL_LSB_TO_G;
    ACCEL_Y_TARE = @as(f32, @floatFromInt(ay_avg)) * ACCEL_LSB_TO_G;
    ACCEL_Z_TARE = @as(f32, @floatFromInt(az_avg)) * ACCEL_LSB_TO_G - 1.0;

    std.log.info("Calibration Performed on ISM330DCL", .{});
    std.log.info("GRYO_X_TARE: {d}", .{GRYO_X_TARE});
    std.log.info("GRYO_Y_TARE: {d}", .{GRYO_Y_TARE});
    std.log.info("GRYO_Z_TARE: {d}", .{GRYO_Z_TARE});
    std.log.info("ACCEL_X_TARE: {d}", .{ACCEL_X_TARE});
    std.log.info("ACCEL_X_TARE: {d}", .{ACCEL_Y_TARE});
    std.log.info("ACCEL_Y_TARE: {d}", .{ACCEL_Z_TARE});
}

pub fn is_imu_ready() struct { accel_ready: bool, gryo_ready: bool } {
    const status: c_int = c.wiringPiI2CReadReg8(FILE, STATUS_REG);

    const accel_bitop: c_int = status & 1;
    const gryo_bitop: c_int = status & 2;

    return .{
        .accel_ready = accel_bitop == 1,
        .gryo_ready = gryo_bitop == 2,
    };
}

pub fn read_gryo() struct { gx: f32, gy: f32, gz: f32 } {
    const lsb_gx: c_int = c.wiringPiI2CReadReg16(FILE, GRYO_OUTX_L_G);
    const lsb_gy: c_int = c.wiringPiI2CReadReg16(FILE, GRYO_OUTY_L_G);
    const lsb_gz: c_int = c.wiringPiI2CReadReg16(FILE, GRYO_OUTZ_L_G);

    return .{
        .gx = @as(f32, @floatFromInt(lsb_gx)) * GRYO_LSB_TO_DEGPS - GRYO_X_TARE,
        .gy = @as(f32, @floatFromInt(lsb_gy)) * GRYO_LSB_TO_DEGPS - GRYO_Y_TARE,
        .gz = @as(f32, @floatFromInt(lsb_gz)) * GRYO_LSB_TO_DEGPS - GRYO_Z_TARE,
    };
}

pub fn read_accel() struct { ax: f32, ay: f32, az: f32 } {
    const lsb_ax: c_int = c.wiringPiI2CReadReg16(FILE, ACCEL_OUTX_L_A);
    const lsb_ay: c_int = c.wiringPiI2CReadReg16(FILE, ACCEL_OUTY_L_A);
    const lsb_az: c_int = c.wiringPiI2CReadReg16(FILE, ACCEL_OUTZ_L_A);

    return .{
        .ax = @as(f32, @floatFromInt(lsb_ax)) * ACCEL_LSB_TO_G - ACCEL_X_TARE,
        .ay = @as(f32, @floatFromInt(lsb_ay)) * ACCEL_LSB_TO_G - ACCEL_Y_TARE,
        .az = @as(f32, @floatFromInt(lsb_az)) * ACCEL_LSB_TO_G - ACCEL_Z_TARE,
    };
}
