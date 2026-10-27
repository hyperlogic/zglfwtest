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

        pub fn zero() Self {
            return Self.init(0.0, 0.0);
        }

        pub fn randomUnit(rng: std.Random) Self {
            const theta = rng.float(T) * 2.0 * std.math.pi;
            return Self.init(@cos(theta), @sin(theta));
        }

        pub fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x + rhs.x, lhs.y + rhs.y);
        }

        pub fn sub(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x - rhs.x, lhs.y - rhs.y);
        }

        pub fn mul(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x * rhs.x, lhs.y * rhs.y);
        }

        pub fn mulScalar(lhs: Self, rhs: T) Self {
            return Self.init(lhs.x * rhs, lhs.y * rhs);
        }

        pub fn div(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x / rhs.x, lhs.y / rhs.y);
        }

        pub fn divScalar(lhs: Self, rhs: T) Self {
            return Self.init(lhs.x / rhs, lhs.y / rhs);
        }

        pub fn dot(lhs: Self, rhs: Self) T {
            return lhs.x * rhs.x + lhs.y * rhs.y;
        }

        pub fn len(self: Self) T {
            return @sqrt(self.dot(self));
        }

        pub fn unit(self: Self) Self {
            const l = self.len();
            return self.divScalar(l);
        }

        pub fn safeUnit(self: Self, safe: Self) Self {
            const l = self.len();
            if (l == 0.0) {
                return safe;
            } else {
                return self.divScalar(l);
            }
        }
    };
}

test "Vec2 compiles" {
    std.testing.refAllDecls(Vec2(f32));
    std.testing.refAllDecls(Vec2(f64));
}

test "Vec2 add" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 1.0);
    const c = a.add(b);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), c.y, 1e-5);
}

test "Vec2 randomUnit" {
    var prng = std.Random.DefaultPrng.init(42);
    const v = Vec2(f32).randomUnit(prng.random());
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), v.dot(v), 1e-5);
}
