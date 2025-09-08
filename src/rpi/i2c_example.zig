const std = @import("std");

const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("linux/i2c.h");
    @cInclude("linux/i2c-dev.h");
    @cInclude("sys/ioctl.h");
});

const SET_CONTRAST = 0x81;
const SET_DISPLAY_ALL_ON_RESUME = 0xA4;
const SET_DISPLAY_ALL_ON = 0xA5;
const SET_NORMAL_DISPLAY = 0xA6;
const SET_INVERT_DISPLAY = 0xA7;
const SET_DISPLAY_OFF = 0xAE;
const SET_DISPLAY_ON = 0xAF;
const SET_DISPLAY_OFstd.fs.T = 0xD3;
const SET_COLUMN_ADDR = 0x21;
const SET_PAGE_ADDR = 0x22;
const SET_COM_PINS = 0xDA;
const SET_VCOM_DETECT = 0xDB;
const SET_DISPLAY_CLOCK_FREQ = 0xD5;
const SET_PRECHARGE = 0xD9;
const SET_MULTIPLEX_RATIO = 0xA8;
const SET_LOW_COLUMN = 0x00;
const SET_HIGH_COLUMN = 0x10;
const SET_START_LINE = 0x40;
const SET_START_PAGE = 0xB0;
const SET_MEMORY_MODE = 0x20;
const SET_COM_SCAN_INC = 0xC0;
const SET_COM_SCAN_DEC = 0xC8;
const SET_SEG_REMAP = 0xA0;
const SET_CHARGE_PUMP = 0x8D;

const screen_width = 128;
const screen_height = 32;
const i2c_addr: c_int = 0x3c;
const i2c_device = "/dev/i2c-1";

// https://www.kernel.org/doc/Documentation/i2c/dev-interface

fn init_display(fd: std.fs.File) !void {
    const cmds = [_]u8{
        SET_MULTIPLEX_RATIO, 0x3F,                   0x00,
        SET_START_LINE,      SET_SEG_REMAP,          SET_COM_SCAN_DEC,
        SET_COM_PINS,        0x32,                   SET_DISPLAY_ALL_ON_RESUME,
        SET_NORMAL_DISPLAY,  SET_DISPLAY_CLOCK_FREQ, 0x80,
        SET_CHARGE_PUMP,     0x14,                   SET_MEMORY_MODE,
        0x20,
    };

    inline for (cmds) |cmd| {
        _ = try fd.write(&[2]u8{ 0x00, cmd });
    }
}

fn display_off(fd: std.fs.File) !void {
    _ = try fd.write(&[2]u8{ 0x00, SET_DISPLAY_OFF });
}

fn display_on(fd: std.fs.File) !void {
    _ = try fd.write(&[2]u8{ 0x00, SET_DISPLAY_ON });
}

fn reset_cursor(fd: std.fs.File) !void {
    const cmds = [_]u8{
        SET_COLUMN_ADDR,
        0x00,
        0x7F,
        SET_PAGE_ADDR,
        0x00,
        0x07,
    };

    inline for (cmds) |cmd| {
        _ = try fd.write(&[2]u8{ 0x00, cmd });
    }
}

fn fill(fd: std.fs.File) !void {
    var i: usize = 0;

    while (i < 1024) {
        _ = try fd.write(&[2]u8{ 0x40, 0xFF });
        i += 1;
    }
}

// zig build-exe src/main.zig -target arm-linux-musleabi -mcpu arm1176jzf_s -O ReleaseSafe -lc
pub fn main() !void {
    const stdout = std.io.getStdOut().outStream();
    const fd = try std.fs.openFileAbsolute(i2c_device, std.fs.File.OpenFlags{ .write = true, .read = true });
    defer fd.close();

    if (c.ioctl(fd.handle, c.I2C_SLAVE, i2c_addr) < 0) {
        try stdout.print("ioctlfail\n", .{});
        return;
    }

    try stdout.print("init\n", .{});
    try display_off(fd);
    try init_display(fd);
    try display_on(fd);
    try reset_cursor(fd);

    try stdout.print("turn on\n", .{});
    try display_on(fd);

    try stdout.print("fill\n", .{});
    try fill(fd);
}
