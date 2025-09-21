const std = @import("std");
const io = @import("io/io.zig");
const buffer = @import("data/buffer.zig");

fn read_timer(timer: *std.time.Timer) u64 {
    const curr_time = timer.read();
    if (curr_time >= std.math.maxInt(u64)) {
        std.log.err("!!! MAX TIME HAS BEEN REACHED !!!", .{});
        timer.reset();
    }
    return curr_time;
}

fn dt(timer: *std.time.Timer) u64 {
    const prev_time: u64 = buffer.read_uint(.time);
    const curr_time: u64 = read_timer(timer);

    if (curr_time > prev_time) {
        return curr_time - prev_time;
    } else {
        return 0;
    }
}

pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();
    try io.setup();

    var loop_timer: std.time.Timer = try std.time.Timer.start();
    while (true) {
        std.log.info("START-IO:{d}", .{timer.read()});
        io.update_io();
        std.log.info("END-IO:{d}", .{timer.read()});

        std.log.info("START-BUFFER_WRITE:{d}", .{timer.read()});
        buffer.write_int(.cycle_count, buffer.read_int(.cycle_count) + 1);
        buffer.write_uint(.dt, dt(&timer));
        buffer.write_uint(.time, read_timer(&timer));
        std.log.info("END-BUFFER_WRITE:{d}", .{timer.read()});

        std.log.info("START-BUFFER_FILE:{d}", .{timer.read()});
        buffer.record() catch |err| {
            std.log.err("{}", .{err});
        };
        std.log.info("START-BUFFER_FILE:{d}", .{timer.read()});

        while (loop_timer.read() <= 1e7) {}
        loop_timer.reset();
    }
    buffer.buffer_stop_recording() catch |err| {
        std.log.err("{}", .{err});
    };
}
