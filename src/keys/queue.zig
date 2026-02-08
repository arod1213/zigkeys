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
        settings: *const Config(T),

        prev: ?models.KeyPress,
        curr: ?models.KeyPress,

        mu: std.Thread.Mutex,

        const Self = @This();
        pub fn init(alloc: Allocator, settings: *const Config(T)) Self {
            return .{
                .alloc = alloc,
                .settings = settings,
                .prev = null,
                .curr = null,
                .mu = std.Thread.Mutex{},
            };
        }

        pub fn clear(self: *Self) void {
            self.mu.lock();
            defer self.mu.unlock();
            self.curr = null;
        }

        pub fn consume(self: *Self, press: models.KeyPress) bool {
            self.mu.lock();
            defer self.mu.unlock();

            if (isRetrigger(press, self.prev)) {
                logThis(self.settings.should_log, .info, "blocked retrigger of {f}", .{press.key});
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
                if (isRelease(press, self.prev)) {
                    logThis(self.settings.should_log, .info, "key was released {f}", .{press.key});
                    self.prev = null;
                    return true;
                }
                return false;
            }
        }

        // pub fn handleKey(self: *Self, press: models.KeyPress) !void {
        //     self.mu.lock();
        //     defer self.mu.unlock();
        //     if (press.key.down) {
        //         if (isRetrigger(press, self.prev)) {
        //             return;
        //         }
        //
        //         if (self.settings.cmdFromKey(press)) |cmd| {
        //             if (self.prev != null and !cmd.shouldTrigger(press, self.prev)) {
        //                 return;
        //             }
        //         }
        //
        //         self.curr = press;
        //         return;
        //     } else {
        //         if (self.prev) |prev| {
        //             if (press.key.eq(prev.key)) {
        //                 self.prev = null;
        //             }
        //         }
        //     }
        // }

        pub fn take(self: *Self) ?models.KeyPress {
            self.mu.lock();
            defer self.mu.unlock();

            const x = self.curr;
            if (x != null) {
                self.prev = x;
            }

            // self.curr = null;
            // put this back if we want to use system key retrigger timing
            return x;
        }
    };
}
