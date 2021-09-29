const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

// Hides the data structure from importing files
const Hidden = struct { i: i32 };

pub const MyInt = opaque {
    const MyIntPtr = *align(@alignOf(Hidden)) @This();

    pub fn init(allocator: *Allocator, i: i32) !MyIntPtr {
        var s: *Hidden = try allocator.create(Hidden);
        s.i = i;
        return @ptrCast(MyIntPtr, s);
    }
    pub fn deinit(self: MyIntPtr, allocator: *Allocator) void {
        allocator.destroy(@ptrCast(*Hidden, self));
    }
    pub fn get(self: MyIntPtr) i32 {
        return @ptrCast(*Hidden, self).i;
    }
};

test "opaque" {
    var ally = testing.allocator;
    const my = try MyInt.init(ally, 2);
    defer my.deinit(ally);

    try testing.expectEqual(@as(i32, 2), my.get());
}
