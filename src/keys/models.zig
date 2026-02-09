const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("./coregraphics.zig").lib;

pub const Modifier = enum(u64) {
    // shift = c.kCGEventFlagMaskShift,
    // control = c.kCGEventFlagMaskControl,
    // option = c.kCGEventFlagMaskAlternate,
    // command = c.kCGEventFlagMaskCommand,
    // fn_key = c.kCGEventFlagMaskSecondaryFn,
    // the above values were not accurate on my machine
    // TODO: add right control, right command, right shift, etc
    shift = 131330,
    control = 262401,
    option = 524576,
    command = 1048840,
    fn_key = 8388864,
};

pub fn modsToNum(modifiers: []const Modifier) ?u64 {
    if (modifiers.len == 0) {
        return null;
    }
    var flags: u64 = 0;
    for (modifiers) |m| {
        flags |= @intFromEnum(m);
    }
    return flags;
}

pub const Key = struct {
    val: u8,
    flags: ?u64,
    down: bool,

    const Self = @This();

    // Deprecated Method
    // pub fn init(key: u8, flags: ?u64, down: bool) Self {
    //     const flag = if (flags) |f| if (f == 256) null else f else null;
    //
    //     return .{
    //         .val = key,
    //         .flags = flag,
    //         .down = down,
    //     };
    // }

    pub fn init(key: u8, flags: []const Modifier, down: bool) Self {
        const flag_num = modsToNum(flags);

        return .{
            .val = key,
            .flags = flag_num,
            .down = down,
        };
    }

    pub fn equalPress(self: Self, other: Self) bool {
        return self.eq(other) and self.down == other.down;
    }

    pub fn eq(self: Self, other: Self) bool {
        const a = self.flags orelse 256;
        const b = other.flags orelse 256;

        return a == b and self.val == other.val;
    }

    pub fn format(self: Self, w: *std.Io.Writer) !void {
        try w.print("key: {d} flag: {d} down: {any}", .{ self.val, self.flags orelse 256, self.down });
    }
};

pub const KeyPress = struct {
    key: Key,
    triggered_at: std.time.Instant,

    const Self = @This();
    pub fn init(key: Key) !Self {
        return .{
            .key = key,
            .triggered_at = try std.time.Instant.now(),
        };
    }

    pub fn ms_diff(self: Self, other: Self) u64 {
        return self.triggered_at.since(other.triggered_at) / 1000000;
    }
};
