const std = @import("std");
const builtin = @import("builtin");

const testing = std.testing;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

// Notice the expression in the return type position
fn createOsSpecificValue() if (builtin.os.tag == .windows) u32 else []const u8 {
    if (builtin.os.tag == .windows)
        return 2
    else
        return "linux";
}

test "Can do conditional compilation, even better" {
    if (builtin.os.tag == .windows)
        try expect(2 == createOsSpecificValue())
    else
        try expect("linux" == createOsSpecificValue());
}

// Notice this doesn't change when called at compile time or async
fn fibonacci(index: u32) u32 {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "Can do generic programming, calculate values at compile time" {
    try expect(fibonacci(7) == 13);
    try comptime expect(fibonacci(7) == 13);
    try await async expect(fibonacci(7) == 13); // just for kicks
}

fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "Can do generics, simple" {
    try expect(max(i32, 0, 3) == 3);
    try expect(max(f32, 0.0, 3.0) == 3.0);
}

fn max2(a: anytype, b: anytype) if (@TypeOf(a) == @TypeOf(b)) @TypeOf(a) else @compileError("Need equal types for max2") {
    if (@TypeOf(a) == bool)
        return a or b
    else
        return if (a > b) a else b;
}

test "Can specialize generics and test compile time conditions" {
    try expect(max2(0, 3) == 3);
    try expect(max2(0.0, 3.0) == 3.0);
    // try expect(max2(0.0, @as(u32, 3)) == 3.0); // This fails at compile time as two different types
    try expect(max2(true, false) == true);
}

test "Can unroll loops" {
    // No code is generated for this test, copy it in main on https://godbolt.org/ and remove last comptime
    const ss = [_][]const u8{ "bob", "rob" };

    comptime var c = 0;
    inline for (ss) |s| c += s.len;
    comptime try expect(c == 6);
    //comptime try expect(c == 5);
}
const fib7 = fibonacci(7);

test "Conatainer level expression are comptime" {
    comptime try expect(fib7 == 13);
}

fn Buffer(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,
        ally: *Allocator,

        const Self = @This();

        fn init(ally: *Allocator, n: usize) !Self {
            return Self{
                .items = try ally.alloc(T, n),
                .len = n,
                .ally = ally,
            };
        }

        fn deinit(self: Self) void {
            self.ally.free(self.items);
        }
    };
}

test "Generic data structures are just functions" {
    var ally = testing.allocator;

    var l = try Buffer(u32).init(ally, 100);
    defer l.deinit();
    try expect(l.len == 100);

    const Point = struct { x: u4, y: u4 };
    var lp = try Buffer(Point).init(ally, 100);
    defer lp.deinit();
    try expect(lp.len == 100);
}

test "An aside, packed structs are so cool" {
    const Point = packed struct { x: u4 = 0, y: u4 = 0, z: u3 = 0, k: u5 = 0 };
    const a: [100]Point = .{.{}} ** 100;
    try testing.expectEqual(2, @sizeOf(Point));
    try testing.expectEqual(@as(usize, 200), std.mem.sliceAsBytes(&a).len);
}
