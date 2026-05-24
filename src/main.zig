const std = @import("std");
const gpio = @import("gpio/gpio.zig");
const buffer = @import("data/buffer.zig");
const options = @import("options.zig");

fn get_time_ns() u64 {
    var ts: std.os.linux.timespec = undefined;
    _ = std.os.linux.clock_gettime(std.os.linux.CLOCK.MONOTONIC, &ts);
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

// Is time with an f32 bad?? should this be u64 ns an cast? idk, could look but I won't
fn time_now() f32 {
    const curr_time = get_time_ns();
    return @as(f32, @floatFromInt(curr_time)) * 1e-9; // ns to s
}

fn dt() f32 {
    // NOTE: ASSUMES BUFFER IS READING PREVIOUS TIME
    const prev_time: f32 = buffer.read_float(.time);
    const curr_time: f32 = time_now();

    if (curr_time > prev_time) {
        return curr_time - prev_time;
    } else {
        return 0.0;
    }
}

pub fn main() !void {
    var buffer_mem: [131072]u8 = undefined; // Reserve a fixed 128kb for memory allocation
    var fba = std.heap.FixedBufferAllocator.init(&buffer_mem);
    const allocator = fba.allocator();

    try gpio.setup();

    // ERROR FREE ZONE
    var loop_start = get_time_ns();
    while (true) {
        // Generic Events
        gpio.update_io();
        buffer.write_int(.cycle_count, buffer.read_int(.cycle_count) + 1);
        buffer.write_float(.dt, dt()); // NOTE: HAS TO BE BEFORE TIME UPDATE
        buffer.write_float(.time, time_now());

        loop_events();

        buffer.record(allocator) catch |err| std.log.err("{}", .{err});
        const elapsed = get_time_ns() - loop_start;
        if (elapsed > options.LOOP_RATE_NS) std.log.err(
            "Loop timer exceeding desired loop rate of: {d}",
            .{options.LOOP_RATE_NS},
        );
        while (get_time_ns() - loop_start <= options.LOOP_RATE_NS) {}
        loop_start = get_time_ns();
    }
    buffer.stop_recording(allocator) catch |err| std.log.err("{}", .{err});
}

pub fn sin_centered(time: f32, time_offset: f32, center: f32, hz: f32, amp: f32) f32 {
    return amp * @sin((time - time_offset) * 2.0 * std.math.pi * hz) + center;
}

fn loop_events() void {
    const time: f32 = buffer.read_float(.time);

    if (@mod(@as(i32, @intFromFloat(time)), 10) == 0) {
        buffer.write_int(.led_01, 1);
    } else {
        buffer.write_int(.led_01, 0);
    }
}
