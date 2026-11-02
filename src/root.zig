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

pub fn run(
    io: std.Io,
    arena: Allocator,
    comptime T: type,
    settings: *const Config(T),
    ctx: anytype,
    callback: fn (@TypeOf(ctx), KeyCommand(T)) anyerror!void,
) !void {
    var queue = KeyQueue(T).init(io, arena, settings);

    const handle = try std.Thread.spawn(.{}, keys.handleKeys, .{ T, &queue });
    defer handle.join();

    while (true) {
        if (try queue.take()) |press| {
            if (settings.cmdFromKey(press)) |key_cmd| {
                try callback(ctx, key_cmd);
                if (key_cmd.trigger_per_ms == 0 or !key_cmd.retrigger) {
                    try queue.clear();
                } else {
                    const dur = std.Io.Clock.Duration{
                        .clock = .awake,
                        .raw = std.Io.Duration{
                            .nanoseconds = std.time.ns_per_ms * key_cmd.trigger_per_ms,
                        },
                    };
                    const timeout = std.Io.Timeout{
                        .duration = dur,
                    };
                    try timeout.sleep(io);
                }
            }
        }

        const dur = std.Io.Clock.Duration{
            .clock = .awake,
            .raw = std.Io.Duration{ .nanoseconds = std.time.ns_per_ms * 3 },
        };
        const timeout = std.Io.Timeout{
            .duration = dur,
        };
        try timeout.sleep(io);
    }
}
