const std = @import("std");
const Allocator = std.mem.Allocator;

const keys = @import("keys");
const KeyQueue = keys.KeyQueue;
const KeyPress = keys.KeyPress;

pub const Config = keys.Config;
pub const KeyCommand = keys.KeyCommand;
pub const Key = keys.Key;
pub const Modifier = keys.Modifier;

pub fn run(arena: Allocator, comptime T: type, settings: *const Config(T), callback: fn (KeyCommand(T)) anyerror!void) !void {
    var queue = KeyQueue(T).init(arena, settings);

    const handle = try std.Thread.spawn(.{}, keys.handleKeys, .{ T, &queue });
    defer handle.join();

    while (true) {
        if (queue.take()) |press| {
            if (settings.cmdFromKey(press)) |key_cmd| {
                try callback(key_cmd);
                if (key_cmd.trigger_per_ms == 0 or !key_cmd.retrigger) {
                    queue.clear();
                } else {
                    std.Thread.sleep(std.time.ns_per_ms * key_cmd.trigger_per_ms);
                }
            }
        }
        std.Thread.sleep(std.time.ns_per_ms * 3);
    }
}
