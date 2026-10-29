const std = @import("std");

pub fn Vec4(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Vec4 is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,
        w: T,

        pub fn init(x: T, y: T, z: T, w: T) Self {
            return Self{ .x = x, .y = y, .z = z, .w = w };
        }

        pub fn zero() Self {
            return Self.init(0.0, 0.0, 0.0, 0.0);
        }

        pub fn add(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
        }

        pub fn sub(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
        }

        pub fn mul(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
        }

        pub fn mulScalar(lhs: Self, rhs: T) Self {
            return Self.init(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
        }

        pub fn div(lhs: Self, rhs: Self) Self {
            return Self.init(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);
        }

        pub fn divScalar(lhs: Self, rhs: T) Self {
            return Self.init(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
        }

        pub fn dot(lhs: Self, rhs: Self) T {
            return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w;
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

        pub fn fuzzyEqual(lhs: Self, rhs: Self, eps: T) bool {
            return @abs(lhs.x - rhs.x) <= eps and @abs(lhs.y - rhs.y) <= eps and @abs(lhs.z - rhs.z) <= eps and @abs(lhs.w - rhs.w) <= eps;
        }
    };
}

test "Vec4 compiles" {
    std.testing.refAllDecls(Vec4(f32));
}

test "Vec4 zero" {
    const a = Vec4(f32).zero();
    try std.testing.expectEqual(@as(f32, 0.0), a.x);
    try std.testing.expectEqual(@as(f32, 0.0), a.y);
    try std.testing.expectEqual(@as(f32, 0.0), a.z);
    try std.testing.expectEqual(@as(f32, 0.0), a.w);
}

test "Vec4 add" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = Vec4(f32).init(5.0, 6.0, 7.0, 8.0);
    const c = a.add(b);
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 8.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 10.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 12.0), c.w, 1e-5);
}

test "Vec4 sub" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = Vec4(f32).init(5.0, 6.0, 7.0, 8.0);
    const c = a.sub(b);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.w, 1e-5);
}

test "Vec4 mul" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = Vec4(f32).init(5.0, 6.0, 7.0, 8.0);
    const c = a.mul(b);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 12.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 21.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 32.0), c.w, 1e-5);
}

test "Vec4 mulScalar" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = @as(f32, 5.0);
    const c = a.mulScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 10.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 15.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 20.0), c.w, 1e-5);
}

test "Vec4 div" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = Vec4(f32).init(5.0, 6.0, 7.0, 8.0);
    const c = a.div(b);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / 6.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / 7.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / 8.0), c.w, 1e-5);
}

test "Vec4 divScalar" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = @as(f32, 5.0);
    const c = a.divScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / 5.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / 5.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / 5.0), c.w, 1e-5);
}

test "Vec4 dot" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const b = Vec4(f32).init(5.0, 6.0, 7.0, 8.0);
    const c = a.dot(b);
    try std.testing.expectApproxEqAbs(@as(f32, 70.0), c, 1e-5);
}

test "Vec4 len" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const len = a.len();
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(30.0)), len, 1e-5);
}

test "Vec4 unit" {
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const c = a.unit();
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(30.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(30.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / @sqrt(30.0)), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / @sqrt(30.0)), c.w, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);

    const b = Vec4(f32).zero();
    const d = b.unit();
    try std.testing.expect(std.math.isNan(d.x));
    try std.testing.expect(std.math.isNan(d.y));
}

test "Vec4 safeUnit" {
    const safe = Vec4(f32).init(2.0, 0.0, 0.0, 0.0);
    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);
    const c = a.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(30.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(30.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / @sqrt(30.0)), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / @sqrt(30.0)), c.w, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);
    const b = Vec4(f32).zero();
    const d = b.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), d.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.w, 1e-5);
    try std.testing.expectApproxEqAbs(d.len(), 1.0, 1e-5);
}

test "Vec4 fuzzyEqual" {
    const eps = @as(f32, 0.0625);
    const small_eps = @as(f32, eps / 2.0);
    const large_eps = @as(f32, eps * 2.0);

    const a = Vec4(f32).init(1.0, 2.0, 3.0, 4.0);

    const a_p_eps_x = a.add(Vec4(f32).init(eps, 0.0, 0.0, 0.0));
    const a_s_eps_x = a.sub(Vec4(f32).init(eps, 0.0, 0.0, 0.0));
    const a_p_eps_y = a.add(Vec4(f32).init(0.0, eps, 0.0, 0.0));
    const a_s_eps_y = a.sub(Vec4(f32).init(0.0, eps, 0.0, 0.0));
    const a_p_eps_z = a.add(Vec4(f32).init(0.0, 0.0, eps, 0.0));
    const a_s_eps_z = a.sub(Vec4(f32).init(0.0, 0.0, eps, 0.0));
    const a_p_eps_w = a.add(Vec4(f32).init(0.0, 0.0, 0.0, eps));
    const a_s_eps_w = a.sub(Vec4(f32).init(0.0, 0.0, 0.0, eps));

    const a_p_small_eps_x = a.add(Vec4(f32).init(small_eps, 0.0, 0.0, 0.0));
    const a_s_small_eps_x = a.sub(Vec4(f32).init(small_eps, 0.0, 0.0, 0.0));
    const a_p_small_eps_y = a.add(Vec4(f32).init(0.0, small_eps, 0.0, 0.0));
    const a_s_small_eps_y = a.sub(Vec4(f32).init(0.0, small_eps, 0.0, 0.0));
    const a_p_small_eps_z = a.add(Vec4(f32).init(0.0, 0.0, small_eps, 0.0));
    const a_s_small_eps_z = a.sub(Vec4(f32).init(0.0, 0.0, small_eps, 0.0));
    const a_p_small_eps_w = a.add(Vec4(f32).init(0.0, 0.0, 0.0, small_eps));
    const a_s_small_eps_w = a.sub(Vec4(f32).init(0.0, 0.0, 0.0, small_eps));

    const a_p_large_eps_x = a.add(Vec4(f32).init(large_eps, 0.0, 0.0, 0.0));
    const a_s_large_eps_x = a.sub(Vec4(f32).init(large_eps, 0.0, 0.0, 0.0));
    const a_p_large_eps_y = a.add(Vec4(f32).init(0.0, large_eps, 0.0, 0.0));
    const a_s_large_eps_y = a.sub(Vec4(f32).init(0.0, large_eps, 0.0, 0.0));
    const a_p_large_eps_z = a.add(Vec4(f32).init(0.0, 0.0, large_eps, 0.0));
    const a_s_large_eps_z = a.sub(Vec4(f32).init(0.0, 0.0, large_eps, 0.0));
    const a_p_large_eps_w = a.add(Vec4(f32).init(0.0, 0.0, 0.0, large_eps));
    const a_s_large_eps_w = a.sub(Vec4(f32).init(0.0, 0.0, 0.0, large_eps));

    try std.testing.expect(a.fuzzyEqual(a, eps));

    try std.testing.expect(a.fuzzyEqual(a_p_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_eps_z, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_z, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_eps_w, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_eps_w, eps));

    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_x, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_y, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_z, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_z, eps));
    try std.testing.expect(a.fuzzyEqual(a_p_small_eps_w, eps));
    try std.testing.expect(a.fuzzyEqual(a_s_small_eps_w, eps));

    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_x, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_x, eps));
    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_y, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_y, eps));
    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_z, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_z, eps));
    try std.testing.expect(!a.fuzzyEqual(a_p_large_eps_w, eps));
    try std.testing.expect(!a.fuzzyEqual(a_s_large_eps_w, eps));
}
