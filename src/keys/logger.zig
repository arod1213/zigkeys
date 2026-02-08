const std = @import("std");

const LogType = enum { info, err, warn };
pub fn logThis(should_log: bool, log_type: LogType, comptime format: []const u8, args: anytype) void {
    if (should_log) {
        switch (log_type) {
            .info => std.log.info(format, args),
            .warn => std.log.warn(format, args),
            .err => std.log.err(format, args),
        }
    }
}
