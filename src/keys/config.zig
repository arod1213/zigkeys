const std = @import("std");
const Allocator = std.mem.Allocator;

const t = @import("./models.zig");
const b = @import("./binds.zig");
const q = @import("./queue.zig");
const KeyQueue = q.KeyQueue;
const KeyCommand = b.KeyCommand;
const Key = t.Key;
const Modifier = t.Modifier;
const Config = b.Config;
const handleKeys = @import("./handler.zig").handleKeys;

pub fn readKeyFromInput(alloc: Allocator) ?Key {
    const T = @TypeOf(null);
    const settings = Config(T).init(&[_]KeyCommand(T){});
    var queue = KeyQueue(T).init(alloc, &settings);

    _ = try std.Thread.spawn(.{}, handleKeys, .{ T, &queue });

    if (queue.take()) |press| {
        return press.key;
    }
    return null;
}
