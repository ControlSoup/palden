const std = @import("std");
const rpi = @import("rpi/blink.zig");

pub fn main() !void {
    std.debug.print("Testing Out Blink\n", .{});
    try rpi.setup();
    while (true) {
        rpi.update_io();
    }
}
