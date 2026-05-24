const std = @import("std");
const Io = std.Io;

const CONFIG_FILE_NAME: []const u8 = "config/data_info.json";

var IS_RECORDING: bool = false;
pub fn is_recording() bool {
    return IS_RECORDING;
}

var ID: u32 = undefined;
var PREFIX: []const u8 = undefined;
var DATA_FILE: Io.File = undefined;

fn getIo() Io {
    return Io.Threaded.global_single_threaded.io();
}

pub fn start_recording(in_allocator: std.mem.Allocator) !void {
    const io = getIo();
    var arena: std.heap.ArenaAllocator = .init(in_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    if (IS_RECORDING) {
        std.log.err(
            "Attempted to start recording, but is already recording: {s}-{d}.csv",
            .{ PREFIX, ID },
        );
        return error.AlreadyRecording;
    }

    // Read the file
    const config_file = try Io.Dir.cwd().openFile(io, CONFIG_FILE_NAME, .{ .mode = .read_write });
    defer config_file.close(getIo());
    var buffer: [50]u8 = undefined;
    const bytes_read: usize = try config_file.readPositionalAll(io, &buffer, 0);

    const parsed: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        buffer[0..bytes_read],
        .{},
    );

    const id_object = parsed.value.object.get("ID") orelse {
        return error.JsonParseError;
    };

    const prefix_object = parsed.value.object.get("PREFIX") orelse {
        return error.JsonParseError;
    };

    // Update the current values of the data recorder
    ID = (try std.json.parseFromValue(u32, allocator, id_object, .{})).value;

    // Store PREFIX in persistent allocator (arena will die at end of function)
    const prefix_value = (try std.json.parseFromValue([]const u8, allocator, prefix_object, .{})).value;
    PREFIX = try in_allocator.dupe(u8, prefix_value);

    // Assemble the new file
    const start = "{";
    const end = "}";
    const new_file = try std.fmt.allocPrint(
        allocator,
        "{s}\"ID\":{d},\"PREFIX\":\"{s}\"{s}\n",
        .{ start, ID + 1, PREFIX, end },
    );

    // Re-write the file with the new index
    const config_write = try Io.Dir.cwd().createFile(getIo(), CONFIG_FILE_NAME, .{});
    defer config_write.close(getIo());
    try config_write.writeStreamingAll(getIo(), new_file);

    DATA_FILE = try Io.Dir.cwd().createFile(getIo(), try std.fmt.allocPrint(allocator, "data/{s}-{d}.csv", .{ PREFIX, ID }), .{ .exclusive = true });
    try DATA_FILE.writeStreamingAll(getIo(), "");

    IS_RECORDING = true;

    std.log.info("Started Logging: {s}-{d}.csv", .{ PREFIX, ID });
}

pub fn write_line(line: []u8) !void {
    try DATA_FILE.writeStreamingAll(getIo(), line);
}

pub fn stop_recording(in_allocator: std.mem.Allocator) !void {
    DATA_FILE.close(getIo());
    IS_RECORDING = false;
    in_allocator.free(PREFIX);
    std.log.info("Stopped Logging", .{});
}
