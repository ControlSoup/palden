const std = @import("std");
const io = @import("rpi/io.zig");

pub fn main() !void {
    std.debug.print("Testing Out Blink\n", .{});
    try io.setup();
    while (true) {
        io.update_io();
    }
}
