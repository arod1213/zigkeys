const std = @import("std");
const Allocator = std.mem.Allocator;

const keys = @import("keys");
const KeyQueue = keys.KeyQueue;
const KeyPress = keys.KeyPress;

pub const Config = keys.Config;
pub const KeyCommand = keys.KeyCommand;
pub const Key = keys.Key;
pub const Modifier = keys.Modifier;
pub const Side = keys.Side;

pub fn run(arena: Allocator, io: std.Io, comptime T: type, settings: *const Config(T), ctx: anytype, callback: fn (@TypeOf(ctx), KeyCommand(T)) anyerror!void) !void {
    var queue = KeyQueue(T).init(arena, io, settings);

    const handle = try std.Thread.spawn(.{}, keys.handleKeys, .{ T, &queue });
    defer handle.join();

    while (true) {
        if (queue.take()) |press| {
            if (settings.cmdFromKey(press)) |key_cmd| {
                try callback(ctx, key_cmd);
                if (key_cmd.trigger_per_ms == 0 or !key_cmd.retrigger) {
                    queue.clear();
                } else {
                    const duration = std.Io.Duration.fromMilliseconds(@intCast(key_cmd.trigger_per_ms));
                    io.sleep(duration, .real) catch {};
                }
            }
        }
        const duration = std.Io.Duration.fromMilliseconds(3);
        io.sleep(duration, .real) catch {};
    }
}
