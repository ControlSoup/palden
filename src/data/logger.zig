const std = @import("std");
const fba = @import("../fba.zig");

const CONFIG_FILE_NAME: []const u8 = "config/data_info.json";

var IS_RECORDING: bool = false;
pub fn is_recording() bool {
    return IS_RECORDING;
}

var ID: u32 = undefined;
var PREFIX: []const u8 = undefined;
var DATA_FILE: std.fs.File = undefined;

pub fn start_recording() !void {
    if (IS_RECORDING) {
        std.log.err(
            "Attempted to start recording, but is already recording: {s}-{d}.csv",
            .{ PREFIX, ID },
        );
        return error.AlreadyRecording;
    }

    // Read the file
    const config_read = try std.fs.cwd().openFile(
        CONFIG_FILE_NAME,
        .{ .mode = .read_write },
    );
    var buffer: [50]u8 = undefined;
    const bytes_read: usize = try config_read.read(&buffer);
    config_read.close();

    // Parse the contents of the config file
    var pre_allocated = std.heap.FixedBufferAllocator.init(&fba.pre_allocated_data);
    const allocator = pre_allocated.allocator();

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
    PREFIX = (try std.json.parseFromValue([]const u8, allocator, prefix_object, .{})).value;

    // Assemble the new file
    const start = "{";
    const end = "}";
    const new_file = try std.fmt.allocPrint(
        allocator,
        "{s}\"ID\":{d},\"PREFIX\":\"{s}\"{s}\n",
        .{ start, ID + 1, PREFIX, end },
    );

    // Re-write the file with the new index
    const config_write = try std.fs.cwd().createFile(
        CONFIG_FILE_NAME,
        .{},
    );
    defer config_write.close();
    const written_bytes = try config_write.write(new_file);

    if (written_bytes != new_file.len) {
        std.log.err(
            "Written bytes does not match new file length (data_info.json) [{d}] vs [{d}]",
            .{ written_bytes, new_file.len },
        );
        return error.FileWriteError;
    }

    DATA_FILE = try std.fs.cwd().createFile(
        try std.fmt.allocPrint(
            allocator,
            "data/{s}-{d}.csv",
            .{ PREFIX, ID },
        ),
        .{ .exclusive = true },
    );
    _ = try DATA_FILE.write("");

    IS_RECORDING = true;
}

pub fn write_line(line: []u8) !void {
    _ = try DATA_FILE.write(line);
}

pub fn stop_recording() !void {
    DATA_FILE.close();
    IS_RECORDING = false;
}
