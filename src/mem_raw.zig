const std = @import("std");
const testing = std.testing;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Alignment of types" {
    // types and arrays align the same
    try expectEqual(@sizeOf(u8), @alignOf(u8));
    try expectEqual(@sizeOf(u32), @alignOf(u32));
    try expectEqual(@alignOf(u8), @alignOf([3]u8));
    try expectEqual(@alignOf(u32), @alignOf([3]u32));
    try expectEqual(@alignOf(u32), @alignOf([3]f32));

    // structs align to the biggest field
    const s = struct { a: u8, b: u128, c: i64 };
    try expectEqual(@alignOf(s), @alignOf(u128));

    // packed structs align to byte
    const s1 = packed struct { a: u128, b: u8 };
    try expectEqual(@alignOf(s1), @alignOf(u8));

    // sub-byte integers align to the closest full integer that contains them
    try expectEqual(@alignOf(u8), @alignOf(u4));
    try expectEqual(@alignOf(u16), @alignOf(u12));

    // We are on a 64 bits machine
    try expectEqual(@alignOf(usize), @alignOf(u64));

    // bool consume one byte and align to byte if not packed
    try expectEqual(@alignOf(u8), @alignOf(bool));
}

const E = enum { bob, rob };
const E16 = enum(u16) { bob, rob };
const E160 = enum(u16) { bob };
const E0 = enum { bob };

const EU = enum(u5) { a, b };
const U32 = union { a: u3, b: u32 };
const U32E5 = union(EU) { a: u3, b: u32 };
const U32E = union(enum) { a: u3, b: u32 };
const U32P = packed union { bob: u3, rob: u32 }; // packed union cannot be tagged

test "Size of unobvious types" {
    // bool is one byte
    try expectEqual(@sizeOf(u8), @sizeOf(bool));

    const zeroBitTypes = [_]type{ void, comptime_int, comptime_float, u0, i0, [0]u8, enum { one }, struct {
        const x = 1;
    }, union { x: void }, *void };
    inline for (zeroBitTypes) |z| try expectEqual(0, @sizeOf(z));

    // enums are one byte normally, unless you specify otherwise
    try expectEqual(@sizeOf(u8), @sizeOf(E));
    try expectEqual(@sizeOf(u16), @sizeOf(E16));
    try expectEqual(@sizeOf(u16), @sizeOf(E160));
    // One value enums are zero bytes
    try expectEqual(0, @sizeOf(E0));

    // Unions are more than the largest value
    try expect(@sizeOf(U32) > @sizeOf(u32));
    try expect(@sizeOf(U32E) > @sizeOf(u32));
    try expect(@sizeOf(U32E) > @sizeOf(u32));
    try expect(@sizeOf(U32E5) > @sizeOf(u32));
    try expectEqual(@sizeOf(u32) * 2, @sizeOf(U32E5)); // Using a small enum type doesn't change the size of a tagged union?

    // Packed unions as exactly as large as the largest value
    try expectEqual(@sizeOf(u32), @sizeOf(U32P));

    // Pointers are 8 bytes on 64 archs
    try expectEqual(@sizeOf(u64), @alignOf([]u8));
    try expectEqual(@alignOf(*u32), @alignOf([]u8));

    // Errors are u16 enums
    try expectEqual(@sizeOf(u16), @sizeOf(anyerror));
    // Error union types are more than the largest because they have to keep an indicator field
    try expect(@sizeOf(u16) < @sizeOf(anyerror!u32));

    // Optional types are bigger than normal types because they have to keep an indicator field
    try expect(@sizeOf(u8) < @sizeOf(?u8));
    // But optional pointers are the same size as they use the 0 value for null
    try expectEqual(@sizeOf(*u8), @sizeOf(?*u8));
}

test "Can specify alignment" {
    var foo: u8 align(4) = 100;
    try expect(@typeInfo(@TypeOf(&foo)).Pointer.alignment == 4);
    try expect(@TypeOf(&foo) == *align(4) u8);

    const as_pointer_to_array: *[1]u8 = &foo;
    const as_slice: []u8 = as_pointer_to_array;
    try expect(@TypeOf(as_slice) == []align(4) u8);
}
fn derp() align(@sizeOf(usize) * 2) i32 {
    return 1234;
}
fn noop1() align(1) void {}
fn noop4() align(4) void {}

test "Can align functions, some architectures need it" {
    try expect(derp() == 1234);
    try expect(@TypeOf(noop1) == fn () align(1) void);
    try expect(@TypeOf(noop4) == fn () align(4) void);
    noop1();
    noop4();
}

test "Can cast to a bigger alignment" {
    var a: u32 = 2;
    var b = @ptrCast(*u8, &a);
    try expectEqual(1, @alignOf(@TypeOf(b.*)));
    var c = @alignCast(4, b);
    try expectEqual(*align(4) u8, @TypeOf(c));
    try expectEqual(4, @typeInfo(@TypeOf(c)).Pointer.alignment);
}

test "Bit twiddling" {
    // Bit casting a type to another
    const a = [_]u8{ 0xFF, 0xFF, 0xFF, 0xFF };
    try expectEqual(@as(u32, 0xFFFFFFFF), @bitCast(u32, a));

    // Bit and byte offsetting
    const S = packed struct { x: u4, y: u5, z: u4 };
    try expectEqual(4, @bitOffsetOf(S, "y"));
    try expectEqual(9, @bitOffsetOf(S, "z"));
    try expectEqual(13, @bitSizeOf(S));
    try expectEqual(1, @offsetOf(S, "z"));
}

test "Pointer Casting" {
    var c: u32 = 33;
    var d = @ptrCast(*u32, &c);
    _ = d;
}
