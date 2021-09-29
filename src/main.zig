const std = @import("std");

const Allocator = std.mem.Allocator;

fn testLeakDetection(allocator: *Allocator, doTheTest: bool) !void {
    var h = try allocator.alloc(u8, 10);
    _ = h;
    if (!doTheTest) allocator.free(h);
}

fn testDoubleFree(allocator: *Allocator, doTheTest: bool) !void {
    var h = try allocator.alloc(u8, 10);
    _ = h;
    allocator.free(h);
    if (doTheTest) allocator.free(h);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;
    try testLeakDetection(allocator, false); // detect leaks
    try testDoubleFree(allocator, false); // segfaults in debug, not release

    try testLeakDetection(std.heap.page_allocator, true); // doesn't detect leaks
    try testDoubleFree(std.heap.page_allocator, false); // segfaults in debug, not in release

    var buffer: [30]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    try testLeakDetection(&fba.allocator, true); // Cannot leak
    try testDoubleFree(&fba.allocator, true); // Cannot be impacted as free is a noop

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    try testLeakDetection(&arena.allocator, true); // doesn't detect leaks
    try testDoubleFree(&arena.allocator, true); // no problem freeing multiple times as it is a noop

    arena = std.heap.ArenaAllocator.init(&gpa.allocator); // use a gpa to detect leaks
    defer arena.deinit();
    try testLeakDetection(&arena.allocator, true); // doesn't detect leaks
    try testDoubleFree(&arena.allocator, true); // no problem freeing multiple times as it is a noop

    const fallback_allocator = std.heap.page_allocator;
    var stack_allocator = std.heap.stackFallback(4096, fallback_allocator);
    try testLeakDetection(&stack_allocator.allocator, true); // it depends on the fallback allocator
}

test {
    _ = @import("mem_bugs.zig");
    _ = @import("mem_raw.zig");
    _ = @import("comptime.zig");
    _ = @import("opaque.zig");
}
