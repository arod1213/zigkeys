const std = @import("std");
const c = @import("./coregraphics.zig").lib;

const t = @import("./models.zig");
const b = @import("./binds.zig");
const q = @import("./queue.zig");
pub const KeyQueue = q.KeyQueue;
pub const KeyCommand = b.KeyCommand;
pub const Key = t.Key;
pub const KeyPress = t.KeyPress;
pub const Modifier = t.Modifier;
pub const Config = b.Config;
// int getFocusedAppPID() {
//     CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
//     CFIndex count = CFArrayGetCount(windowList);
//
//     for (CFIndex i = 0; i < count; i++) {
//         CFDictionaryRef window = (CFDictionaryRef)CFArrayGetValueAtIndex(windowList, i);
//         CFNumberRef pidRef = (CFNumberRef)CFDictionaryGetValue(window, kCGWindowOwnerPID);
//         int pid;
//         if (CFNumberGetValue(pidRef, kCFNumberIntType, &pid)) {
//             CFRelease(windowList);
//             return pid;
//         }
//     }
//
//     CFRelease(windowList);
//     return -1; // No valid window found
// }

// fn getFocusedAppPID() u32 {
//     const window_list: c.CFArrayRef = c.CGWindowListCopyWindowInfo(
//         c.kCGWindowListOptionOnScreenOnly | c.kCGWindowListExcludeDesktopElements,
//         c.kCGNullWindowID,
//     );
//     defer c.CFRelease(window_list);
//
//     const count = c.CFArrayGetCount(window_list);
//     for (0..@intCast(count)) |idx| {
//         const window: c.CFDictionaryRef = @ptrCast(@alignCast(c.CFArrayGetValueAtIndex(window_list, @intCast(idx))));
//         const pidRef: c.CFNumberRef = @ptrCast(@alignCast(c.CFDictionaryGetValue(window, c.kCGWindowOwnerPID)));
//         var pid: c_int = undefined;
//         const rc = c.CFNumberGetValue(pidRef, c.kCFNumberIntType, &pid);
//         std.log.info("RC is {d}\n", .{rc});
//
//         if (rc != 0) {
//             return @intCast(pid);
//         }
//     }
//
//     return 0;
// }

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

                    const key_press = t.KeyPress.init(.{
                        .val = @intCast(keycode),
                        .flags = flags,
                        .down = is_down,
                    }) catch @panic("invalid key");
                    queue_ptr.handleKey(key_press) catch @panic("could not handle key press");
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
