const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const models = @import("./models.zig");
const Key = models.Key;
const KeyPress = models.KeyPress;

pub fn Config(comptime T: type) type {
    const CommandType = KeyCommand(T);
    return struct {
        key_commands: []const CommandType,
        isGlobal: bool = false,
        shouldLog: bool = false,

        const Self = @This();
        pub fn init(key_commands: []const CommandType) Self {
            return .{
                .key_commands = key_commands,
            };
        }

        pub fn cmdFromKey(self: Self, key: KeyPress) ?CommandType {
            for (self.key_commands) |kc| {
                if (kc.eq(key)) {
                    return kc;
                }
            }
            return null;
        }

        pub fn format(self: Self, w: *std.Io.Writer) !void {
            for (self.key_commands) |kc| {
                try w.print("{s} - {f}\n", .{ kc.use, kc.key });
            }
        }
    };
}

pub fn KeyCommand(comptime T: type) type {
    return struct {
        key: Key,
        cmd: T,
        retrigger: bool,
        trigger_per_ms: u64 = 60,
        use: []const u8,

        const Self = @This();

        pub fn init(press: Key, cmd: T, retrigger: bool, use: []const u8) Self {
            return .{
                .key = press,
                .cmd = cmd,
                .retrigger = retrigger,
                .use = use,
            };
        }

        pub fn eq(self: *const Self, other: KeyPress) bool {
            return self.key.eq(other.key);
        }

        pub fn shouldTrigger(self: *const Self, curr: KeyPress, prev: ?KeyPress) bool {
            if (prev == null) return true;
            if (!curr.key.eq(prev.?.key)) return true;
            if (!self.retrigger) return false;
            return self.trigger_per_ms <= curr.ms_diff(prev.?);
        }

        fn format(self: *const Self, w: *std.io.Writer) !void {
            try w.print("key: {f} cmd: {f} retrig {any}", .{ self.key, self.cmd, self.retrigger });
        }
    };
}
