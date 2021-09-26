const std = @import("std");

const Allocator = std.mem.Allocator;
const testing = std.testing;

const zu8 = @as(u8, 0);

test "OK: comptime uninitialized memory cannot be read" {
    const s: [3]u8 = undefined;
    _ = s;
    //try testing.expectEqual(0, s[0..][0]);
    const u: u8 = undefined;
    _ = u;
    // try testing.expectEqual(0, u);
}

test "OK: cannot buffer overflow easily thanks to slices, panics at runtime or compile time error" {
    const array: [5]u8 = "hello".*;
    //_ = array[5];
    _ = array;

    var s = [_]u8{ 1, 2, 3 };
    _ = s;
    // _ = s[0..][4];

    var ally = testing.allocator;
    var h: []u8 = try ally.alloc(u8, 3);
    defer ally.free(h);

    // _ = h[4];
}

test "OK: memory leaks are checked for some allocators" {
    var ally = testing.allocator;
    var h: []u8 = try ally.alloc(u8, 3);
    _ = h;
    defer ally.free(h);

    // Testing other allocators in test segfaults, run main instead
}

fn addrLocal(x: u8) []u8 {
    var l = [_]u8{ x, x, x };
    return l[0..];
}

test "FAIL: can read stack destroyed variable" {
    var s = addrLocal(3);
    try testing.expect(3 == s[0]);

    _ = addrLocal(2);
    //try testing.expect(3 == s[0]); // Apparently you need to call the function twice to corrupt the stack
}
test "FAIL: can read runtime stack uninitialized memory" {
    var s: [3]u8 = undefined;
    try testing.expect(zu8 != s[0..][0]);
}

test "FAIL: can read runtime heap uninitialized memory" {
    var ally = testing.allocator;

    var s: []u8 = try ally.alloc(u8, 3);
    defer ally.free(s);

    try testing.expect(zu8 != s[0]);
}
test "FAIL: use after free segfaults, dangling pointer" {
    var ally = testing.allocator;

    var s: []u8 = try ally.alloc(u8, 3);
    ally.free(s);

    //try testing.expect(zu8 != s[0]);
}
