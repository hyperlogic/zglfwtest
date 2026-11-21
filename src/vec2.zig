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

        pub const zero: Self = Self.init(0, 0);
        pub const one: Self = Self.init(1, 1);
        pub const x_axis: Self = Self.init(1, 0);
        pub const y_axis: Self = Self.init(0, 1);

        pub fn init(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.init(self.x + other.x, self.y + other.y);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self.init(self.x - other.x, self.y - other.y);
        }

        pub fn mul(self: Self, other: Self) Self {
            return Self.init(self.x * other.x, self.y * other.y);
        }

        pub fn mulScalar(self: Self, scalar: T) Self {
            return Self.init(self.x * scalar, self.y * scalar);
        }

        pub fn div(self: Self, other: Self) Self {
            return Self.init(self.x / other.x, self.y / other.y);
        }

        pub fn divScalar(self: Self, scalar: T) Self {
            return Self.init(self.x / scalar, self.y / scalar);
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
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
                return safe.unit();
            } else {
                return self.divScalar(l);
            }
        }

        pub fn randomUnit(rng: std.Random) Self {
            const theta = rng.float(T) * 2.0 * std.math.pi;
            return Self.init(@cos(theta), @sin(theta));
        }

        pub fn fuzzyEqual(self: Self, other: Self, eps: T) bool {
            return @abs(self.x - other.x) <= eps and @abs(self.y - other.y) <= eps;
        }
    };
}

test "Vec2 compiles" {
    std.testing.refAllDecls(Vec2(f32));
}

test "Vec2 add" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 3.0);
    const c = a.add(b);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), c.y, 1e-5);
}

test "Vec2 sub" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 3.0);
    const c = a.sub(b);
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), c.y, 1e-5);
}

test "Vec2 mul" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 3.0);
    const c = a.mul(b);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), c.y, 1e-5);
}

test "Vec2 mulScalar" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = @as(f32, 3.0);
    const c = a.mulScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), c.y, 1e-5);
}

test "Vec2 div" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 3.0);
    const c = a.div(b);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.6666666666), c.y, 1e-5);
}

test "Vec2 divScalar" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = @as(f32, 3.0);
    const c = a.divScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 0.333333333), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.666666666), c.y, 1e-5);
}

test "Vec2 dot" {
    const a = Vec2(f32).init(1.0, 2.0);
    const b = Vec2(f32).init(2.0, 3.0);
    const c = a.dot(b);
    try std.testing.expectApproxEqAbs(@as(f32, 8.0), c, 1e-5);
}

test "Vec2 len" {
    const a = Vec2(f32).init(1.0, 2.0);
    const len = a.len();
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(5.0)), len, 1e-5);
}

test "Vec2 unit" {
    const a = Vec2(f32).init(1.0, 2.0);
    const c = a.unit();
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(5.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(5.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);

    const b = Vec2(f32).zero;
    const d = b.unit();
    try std.testing.expect(std.math.isNan(d.x));
    try std.testing.expect(std.math.isNan(d.y));
}

test "Vec2 safeUnit" {
    const safe = Vec2(f32).init(2.0, 0.0);
    const a = Vec2(f32).init(1.0, 2.0);
    const c = a.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(5.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(5.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);
    const b = Vec2(f32).zero;
    const d = b.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), d.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.y, 1e-5);
    try std.testing.expectApproxEqAbs(d.len(), 1.0, 1e-5);
}

test "Vec2 randomUnit" {
    var prng = std.Random.DefaultPrng.init(42);
    for (0..10) |_| {
        const v = Vec2(f32).randomUnit(prng.random());
        try std.testing.expectApproxEqAbs(@as(f32, 1.0), v.dot(v), 1e-5);
    }
}

test "Vec2 fuzzyEqual" {
    const eps = @as(f32, 0.0625);
    const small_eps = @as(f32, eps / 2.0);
    const large_eps = @as(f32, eps * 2.0);

    const a = Vec2(f32).init(1.0, 2.0);

    const a_p_eps_x = a.add(Vec2(f32).init(eps, 0.0));
    const a_s_eps_x = a.sub(Vec2(f32).init(eps, 0.0));
    const a_p_eps_y = a.add(Vec2(f32).init(0.0, eps));
    const a_s_eps_y = a.sub(Vec2(f32).init(0.0, eps));

    const a_p_small_eps_x = a.add(Vec2(f32).init(small_eps, 0.0));
    const a_s_small_eps_x = a.sub(Vec2(f32).init(small_eps, 0.0));
    const a_p_small_eps_y = a.add(Vec2(f32).init(0.0, small_eps));
    const a_s_small_eps_y = a.sub(Vec2(f32).init(0.0, small_eps));

    const a_p_large_eps_x = a.add(Vec2(f32).init(large_eps, 0.0));
    const a_s_large_eps_x = a.sub(Vec2(f32).init(large_eps, 0.0));
    const a_p_large_eps_y = a.add(Vec2(f32).init(0.0, large_eps));
    const a_s_large_eps_y = a.sub(Vec2(f32).init(0.0, large_eps));

    try std.testing.expect(a.fuzzyEqual(a, eps));

    try std.testing.expect(a.fuzzyEqual(a_p_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_y, eps));

    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_y, eps));

    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_x, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_x, eps));
    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_y, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_y, eps));
}
