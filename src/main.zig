const std = @import("std");
const print = std.debug.print;
const posix = std.posix;

const zigkeys = @import("zigkeys");
const Config = zigkeys.Config;
const KeyCommand = zigkeys.KeyCommand;
const Key = zigkeys.Key;
const Modifier = zigkeys.Modifier;

fn setupTermios(handle: posix.fd_t) !void {
    var settings = try posix.tcgetattr(handle);
    settings.lflag.ICANON = false;
    settings.lflag.ECHO = false;
    _ = try posix.tcsetattr(handle, posix.TCSA.NOW, settings);
}

const Msg = union(enum) { a: u8, b, c };

fn handleKp(kc: zigkeys.KeyCommand(Msg)) !void {
    switch (kc.cmd) {
        .a => |x| std.log.info("received a {any} {d}\n", .{ kc.cmd, x }),
        .b => std.log.info("received b {any} \n", .{kc.cmd}),
        .c => std.log.info("received c {any} \n", .{kc.cmd}),
    }
}

pub fn main() !void {
    const stdin = std.fs.File.stdin();
    try setupTermios(stdin.handle);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const T = KeyCommand(Msg);
    const cmds = [_]T{
        T.init(Key.init(0, &[_]Modifier{ .command, .shift }, true), .b, false, "b"),
        T.init(Key.init(0, &[_]Modifier{.shift}, true), .c, false, "c"),
        T.init(
            Key.init(0, &[_]Modifier{.option}, true),
            Msg{ .a = 5 },
            false,
            "c",
        ),
    };
    var config = Config(Msg).init(&cmds);
    config.is_global = false;
    try zigkeys.run(alloc, Msg, &config, handleKp);
}
