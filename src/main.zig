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

pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();
    try io.setup();

    while (true) {
        std.log.info("START-IO:{d}", .{timer.read()});
        io.update_io();
        std.log.info("END-IO:{d}", .{timer.read()});

        std.log.info("START-BUFFER_WRITE:{d}", .{timer.read()});
        buffer.write_int(.cycle_count, buffer.read_int(.cycle_count) + 1);
        buffer.write_time(read_timer(&timer));
        std.log.info("END-BUFFER_WRITE:{d}", .{timer.read()});
        std.log.info("START-BUFFER_FILE:{d}", .{timer.read()});
        buffer.record() catch |err| {
            std.log.err("{}", .{err});
        };
        std.log.info("START-BUFFER_END:{d}", .{timer.read()});
    }
    buffer.buffer_stop_recording() catch |err| {
        std.log.err("{}", .{err});
    };
}
