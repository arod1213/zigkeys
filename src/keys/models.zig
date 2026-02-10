const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("./coregraphics.zig").lib;

// TODO: Implement THIS
pub const Side = enum {
    left,
    right,
    both,
    either,
};

pub fn flagsEquivalent(flag: u64, mods: []const Modifier) bool {
    for (mods) |m| {
        const values = m.possibleValues();
        var contained = false;
        for (values) |val| {
            if ((flag & val) == val) {
                contained = true;
                break;
            }
        }
        if (!contained) {
            return false;
        }
    }
    return true;
}

pub const Modifier = union(enum) {
    shift: Side,
    control: Side,
    option: Side,
    command: Side,
    fn_key,

    pub fn eql(self: Modifier, other: Modifier) bool {
        if (@intFromEnum(self) != @intFromEnum(other)) return false;

        return switch (self) {
            .shift => |side| side == other.shift,
            .control => |side| side == other.control,
            .option => |side| side == other.option,
            .command => |side| side == other.command,
            .fn_key => true,
        };
    }

    pub fn possibleValues(self: Modifier) []const u64 {
        return switch (self) {
            .shift => |x| switch (x) {
                .left => &[_]u64{131330},
                .right => &[_]u64{131332},
                .both => &[_]u64{131334},
                .either => &[_]u64{ 131330, 131332 },
            },
            .control => |x| switch (x) {
                .left => &[_]u64{262401},
                .right => &[_]u64{270592},
                .both => &[_]u64{270953},
                .either => &[_]u64{262401, 270592},
            },
            .option => |x| switch (x) {
                .left => &[_]u64{524576},
                .right => &[_]u64{524608},
                .both => unreachable, // NOT VALID COMMAND
                .either => &[_]u64{524576, 524608},
            },
            .command => |x| switch (x) {
                .left => &[_]u64{1048840},
                .right => &[_]u64{1048848},
                .both => &[_]u64{1048856},
                .either => &[_]u64{1048840, 1048848},
            },
            .fn_key => &[_]u64{8388864},
        };
    }
};

pub const Key = struct {
    val: u8,
    flags: ?u64,
    modifiers: []const Modifier = &[_]Modifier{},
    down: bool,

    const Self = @This();

    pub fn initWithFlags(key: u8, flag: u64, down: bool) Self {
        return .{
            .flags = flag,
            .val = key,
            .down = down,
        };
    }

    pub fn init(key: u8, mods: []const Modifier, down: bool) Self {
        return .{
            .flags = null,
            .modifiers = mods,
            .val = key,
            .down = down,
        };
    }

    fn flagMatches(self: Self, other: Self) bool {
        const self_has_mods = self.modifiers.len > 0;
        const other_has_mods = other.modifiers.len > 0;

        if (self_has_mods and other_has_mods) {
            return std.meta.eql(self.modifiers, other.modifiers);
        } else if (!self_has_mods and other_has_mods) {
            return flagsEquivalent(self.flags orelse 256, other.modifiers);
        } else if (self_has_mods and !other_has_mods) {
            return flagsEquivalent(other.flags orelse 256, self.modifiers);
        } else {
            return (self.flags orelse 256) == (other.flags orelse 256);
        }
    }

    pub fn equalPress(self: Self, other: Self) bool {
        return self.eq(other) and self.down == other.down;
    }

    pub fn eq(self: Self, other: Self) bool {
        return self.flagMatches(other) and self.val == other.val;
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
