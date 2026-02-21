const std = @import("std");
const c = @import("./coregraphics.zig").lib;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const logThis = @import("./logger.zig").logThis;

pub const models = @import("./models.zig");
const KeyPress = models.KeyPress;
const binds = @import("./binds.zig");
const Config = binds.Config;

fn isRetrigger(a: models.KeyPress, b: ?models.KeyPress) bool {
    if (b) |press| {
        return a.key.eq(press.key) and a.key.down == press.key.down;
    }
    return false;
}

fn isRelease(curr: models.KeyPress, prev: ?models.KeyPress) bool {
    if (prev) |press| {
        if (press.key.down) {
            return press.key.eq(curr.key) and curr.key.down == false;
        } else {
            return false;
        }
    }
    return false;
}

pub fn KeyQueue(comptime T: type) type {
    return struct {
        alloc: Allocator,
        io: std.Io,
        settings: *const Config(T),

        prev: ?models.KeyPress,
        curr: ?models.KeyPress,

        mu: std.Io.Mutex,

        const Self = @This();
        pub fn init(alloc: Allocator, io: std.Io, settings: *const Config(T)) Self {
            return .{
                .alloc = alloc,
                .io = io,
                .settings = settings,
                .prev = null,
                .curr = null,
                .mu = std.Io.Mutex.init,
            };
        }

        pub fn clear(self: *Self) void {
            self.mu.lock(self.io) catch return;
            defer self.mu.unlock(self.io);
            self.curr = null;
        }

        pub fn consume(self: *Self, press: models.KeyPress) bool {
            self.mu.lock(self.io) catch return false;
            defer self.mu.unlock(self.io);

            if (isRetrigger(press, self.prev)) {
                logThis(self.settings.should_log, .info, "blocked retrigger of {f} because prev is {f}", .{ press.key, self.prev.?.key });
                return true;
            }

            if (self.settings.cmdFromKey(press)) |cmd| {
                if (self.prev != null and !cmd.shouldTrigger(press, self.prev)) {
                    logThis(self.settings.should_log, .info, "blocked trigger of {f} {f}", .{ press.key, self.prev.?.key });
                    return false;
                }
                self.curr = press;
                return true;
            } else {
                self.prev = null;
                self.curr = null;
                logThis(self.settings.should_log, .info, "key up of {f}", .{press.key});
                return isRelease(press, self.prev);
            }
        }

        pub fn take(self: *Self) ?models.KeyPress {
            self.mu.lock(self.io) catch return null;
            defer self.mu.unlock(self.io);

            const x = self.curr;
            if (x != null) {
                self.prev = x;
            }

            return x;
        }
    };
}
