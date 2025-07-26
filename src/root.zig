const std = @import("std");

pub const SpscErrors = error{
    FullQueue,
    EmptyQueue,
};

pub fn SPSCQueue(comptime T: type, comptime size: usize) type {
    return struct {
        atomic_back: usize = 0,
        atomic_front: usize align(64) = 0,
        cached_back: usize align(64) = 0,
        cached_front: usize align(64) = 0,
        data: [size]T = undefined,

        const Self = @This();

        pub fn init() Self {
            return Self{};
        }

        pub fn push(self: *Self, item: usize) !void {
            const back = @atomicLoad(usize, &self.atomic_back, std.builtin.AtomicOrder.unordered);

            if ((back - self.cached_front) >= self.data.len) {
                self.cached_front = @atomicLoad(usize, &self.atomic_front, std.builtin.AtomicOrder.unordered);
                if ((back - self.cached_front >= self.data.len)) {
                    return SpscErrors.FullQueue;
                }
            }
            self.data[back % self.data.len] = item;
            @atomicStore(usize, &self.atomic_back, back + 1, std.builtin.AtomicOrder.unordered);
            return;
        }

        pub fn pop(self: *Self) !usize {
            const front = @atomicLoad(usize, &self.atomic_front, std.builtin.AtomicOrder.unordered);
            if (front == self.cached_back) {
                self.cached_back = @atomicLoad(usize, &self.atomic_back, std.builtin.AtomicOrder.acquire);
                if (front == self.cached_back) {
                    return SpscErrors.EmptyQueue;
                }
            }
            const ret = self.data[front % self.data.len];
            @atomicStore(usize, &self.atomic_front, front + 1, std.builtin.AtomicOrder.release);
            return ret;
        }
    };
}
