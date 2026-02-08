const std = @import("std");
const c = @import("./coregraphics.zig").lib;
const KeyQueue = @import("./queue.zig").KeyQueue;
const KeyPress = @import("./models.zig").KeyPress;

fn createEventCallback(comptime T: type) fn (c.CGEventTapProxy, c.CGEventType, c.CGEventRef, ?*anyopaque) callconv(.c) c.CGEventRef {
    return struct {
        fn eventCallback(
            _: c.CGEventTapProxy, // proxy
            type_: c.CGEventType,
            event: c.CGEventRef,
            queue: ?*anyopaque,
        ) callconv(.c) c.CGEventRef {
            const queue_ptr: *KeyQueue(T) = @ptrCast(@alignCast(queue));

            switch (type_) {
                10, 11 => { // key presses
                    const flags = switch (c.CGEventGetFlags(event)) {
                        256 => null,
                        else => |x| x,
                    };

                    const keycode = c.CGEventGetIntegerValueField(
                        event,
                        c.kCGKeyboardEventKeycode,
                    );

                    const is_down = type_ == 10;

                    if (queue_ptr.settings.should_log) {
                        std.log.info("key {d} flag {d}", .{ keycode, flags orelse 256 });
                    }

                    const key_press = KeyPress.init(.{
                        .val = @intCast(keycode),
                        .flags = flags,
                        .down = is_down,
                    }) catch @panic("invalid key");

                    if (queue_ptr.consume(key_press) and queue_ptr.settings.propagate == false) {
                        return null;
                    } else {
                        return event;
                    }
                },
                else => {},
            }

            return event;
        }
    }.eventCallback;
}

pub fn handleKeys(comptime T: type, queue: *KeyQueue(T)) void {
    const tap = c.CGEventTapCreate(
        c.kCGSessionEventTap,
        c.kCGHeadInsertEventTap,
        c.kCGEventTapOptionDefault,
        (1 << c.kCGEventKeyDown) | (1 << c.kCGEventKeyUp),
        createEventCallback(T),
        queue,
    );
    if (tap == null) {
        @panic("Missing accessibility permissions");
    }

    const run_loop_source = c.CFMachPortCreateRunLoopSource(null, tap, 0);
    c.CFRunLoopAddSource(
        c.CFRunLoopGetCurrent(),
        run_loop_source,
        c.kCFRunLoopCommonModes,
    );

    c.CGEventTapEnable(tap, true);
    c.CFRunLoopRun();
    std.log.info("KEY LOOP CLOSED", .{});
}
