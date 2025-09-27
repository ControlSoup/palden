const std = @import("std");
const io = @import("io/io.zig");
const buffer = @import("data/buffer.zig");
const options = @import("options.zig");

// Is time with an f32 bad?? should this be u64 ns an cast? idk, could look but I won't
fn time_now(timer: *std.time.Timer) f32 {
    const curr_time = timer.read();
    if (curr_time >= std.math.maxInt(u64)) {
        std.log.err("MAX TIME HAS BEEN REACHED", .{});
        timer.reset();
    }
    return @as(f32, @floatFromInt(curr_time)) * 1e-9; // ns to s
}

fn dt(timer: *std.time.Timer) f32 {

    // NOTE: ASSUMES BUFFER IS READING PREVIOUS TIME
    const prev_time: f32 = buffer.read_float(.time);
    const curr_time: f32 = time_now(timer);

    if (curr_time > prev_time) {
        return curr_time - prev_time;
    } else {
        return 0.0;
    }
}

pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();
    try io.setup();

    buffer.write_float(.servo, 0.0);

    // ERROR FREE ZONE
    var loop_timer: std.time.Timer = try std.time.Timer.start();
    while (true) {
        io.update_io();
        buffer.write_int(.cycle_count, buffer.read_int(.cycle_count) + 1);
        buffer.write_float(.dt, dt(&timer));
        buffer.write_float(.time, time_now(&timer));
        loop_events();

        while (loop_timer.read() <= options.LOOP_RATE_NS) {}
        loop_timer.reset();
    }
    buffer.buffer_stop_recording() catch |err| {
        std.log.err("{}", .{err});
    };
}

pub fn sin_centered(time: f32, time_offset: f32, center: f32, hz: f32, amp: f32) f32 {
    return amp * @sin((time - time_offset) * 2.0 * std.math.pi * hz) + center;
}

var s1: bool = true;
fn loop_events() void {
    const time: f32 = buffer.read_float(.time);

    if (time < 2.0) {
        buffer.write_float(.servo, 0.2);
    } else if (time < 2.0) {
        buffer.write_float(.servo, 0.5);
    } else {
        buffer.write_float(.servo, sin_centered(time, 2.0, 0.5, 0.2, 0.5));
    }
    buffer.record() catch |err| {
        std.log.err("{}", .{err});
    };
}
