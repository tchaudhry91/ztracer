const std = @import("std");
const PTRACE_ME: i32 = 0;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const child = try std.posix.fork();
    if (child == 0) {
        // child process
        try std.posix.ptrace(PTRACE_ME, 0, 0, 0);
        return std.process.execv(allocator, args[1..]);
    } else {
        // parent process
        const result = std.posix.waitpid(child, 0);
        try stdout.print("Result Status:{}", .{result.status});
        if (std.os.linux.W.IFEXITED(result.status)) {
            try stdout.print("wow", .{});
        }
    }

    try bw.flush(); // don't forget to flush!
}
