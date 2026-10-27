const std = @import("std");

pub fn Vec2(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Vec2 is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn init(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x + rhs.x, lhs.y + rhs.y);
        }
    };
}

test "Vec2 add" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 1.0);
    const c = a.add(b);
    try std.testing.expectEqual(@as(f32, 3.0), c.x);
    try std.testing.expectEqual(@as(f32, 3.0), c.y);
}
