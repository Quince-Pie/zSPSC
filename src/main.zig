const std = @import("std");
const spsc = @import("root.zig");

fn producer(queue: *spsc.SPSCQueue(usize, 4096)) !void {
    for (0..1000000000) |i| {
        while (std.meta.isError(queue.push(i))) {
            _ = try std.Thread.yield();
        }
    }
}

fn consumer(queue: *spsc.SPSCQueue(usize, 4096)) !void {
    outer: for (0..1000000000) |_| {
        while (true) {
            if (queue.pop()) |i| {
                // to stuff
                _ = @volatileCast(&i);
                continue :outer;
            } else |_| {
                _ = try std.Thread.yield();
            }
        }
    }
}

pub fn main() !void {
    var queue: spsc.SPSCQueue(usize, 4096) = spsc.SPSCQueue(usize, 4096).init();
    const thread1: std.Thread = try std.Thread.spawn(.{}, producer, .{&queue});
    const thread2: std.Thread = try std.Thread.spawn(.{}, consumer, .{&queue});
    thread1.join();
    thread2.join();
}
