const std = @import("std");
const gpio = @import("gpio/gpio.zig");
const buffer = @import("data/buffer.zig");
const options = @import("options.zig");

// Is time with an f32 bad?? should this be u64 ns an cast? idk, could look but I won't
fn time_now(timer: *std.time.Timer) f32 {
    const curr_time = timer.read();
    if (curr_time >= std.math.maxInt(u64)) {
        std.log.err("MAX TIME HAS BEEN REACHED, TIME WILL LOOP TO ZERO", .{});
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
    var buffer_mem: [16384]u8 = undefined; // Reserve a fixed 16kb for memory allocation
    var fba = std.heap.FixedBufferAllocator.init(&buffer_mem);
    const allocator = fba.allocator();

    var timer: std.time.Timer = try std.time.Timer.start();
    try gpio.setup();

    // ERROR FREE ZONE
    var loop_timer: std.time.Timer = try std.time.Timer.start();
    while (true) {
        // Genreic Events
        gpio.update_io();
        buffer.write_int(.cycle_count, buffer.read_int(.cycle_count) + 1);
        buffer.write_float(.dt, dt(&timer)); // NOTE: HAS TO BE BEFOR TIME UPDATE
        buffer.write_float(.time, time_now(&timer));

        loop_events(allocator);

        if (loop_timer.read() > options.LOOP_RATE_NS) std.log.err(
            "Looptimer exceeding desired looprate of: {s}",
            .{options.LOOP_RATE_NS},
        );
        while (loop_timer.read() <= options.LOOP_RATE_NS) {}
        loop_timer.reset();
    }
    buffer.stop_recording(allocator) catch |err| {
        std.log.err("{}", .{err});
    };
}

pub fn sin_centered(time: f32, time_offset: f32, center: f32, hz: f32, amp: f32) f32 {
    return amp * @sin((time - time_offset) * 2.0 * std.math.pi * hz) + center;
}

fn loop_events(allocator: std.mem.Allocator) void {
    const time: f32 = buffer.read_float(.time);
    _ = time;

    buffer.record(allocator) catch |err| {
        std.log.err("{}", .{err});
    };
}
