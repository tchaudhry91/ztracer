const std = @import("std");
const c = @cImport({
    @cInclude("sys/ptrace.h");
    @cInclude("sys/user.h");
    @cInclude("sys/wait.h");
    @cInclude("errno.h");
});

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const child = try std.posix.fork();
    if (child == 0) {
        // child process
        try std.posix.ptrace(c.PTRACE_TRACEME, 0, 0, 0);
        return std.process.execv(allocator, args[1..]);
    } else {
        // parent process
        _ = std.posix.waitpid(child, 0);
        while (true) {
            try std.posix.ptrace(c.PTRACE_SYSCALL, child, 0, 0);
            const res = std.posix.waitpid(child, 0);
            if (std.os.linux.W.IFEXITED(res.status)) {
                break;
            }
        }
    }
}
