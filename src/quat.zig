const std = @import("std");
const Mat3 = @import("mat3.zig").Mat3;
const Mat4 = @import("mat4.zig").Mat4;
const Vec3 = @import("vec3.zig").Vec3;
const Vec4 = @import("vec4.zig").Vec4;

pub const Quatf = Quat(f32);
pub const Quatd = Quat(f64);

pub fn Quat(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Quat is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,
        w: T,

        pub const identity: Self = Self.init(0, 0, 0, 1);

        pub fn init(x: T, y: T, z: T, w: T) Self {
            return Self{ .x = x, .y = y, .z = z, .w = w };
        }

        pub fn initAxisAngle(axis: Vec3(T), angle: T) Self {
            const l = axis.len();
            const n = axis.mulScalar(@sin(angle / 2.0) / l);
            const w = @cos(angle / 2.0);
            return Self.init(n.x, n.y, n.z, w);
        }

        pub fn initMat4(m: Mat4(T)) Self {
            return initMat3(m.extractMat3());
        }

        pub fn initMat3(m: Mat3(T)) Self {
            // put the 3x3 part of m into local vars
            var a = m.x.x;
            var b = m.y.x;
            var c = m.z.x;
            var d = m.x.y;
            var e = m.y.y;
            var f = m.z.y;
            var g = m.x.z;
            var h = m.y.z;
            var i = m.z.z;
            // compute det of 3x3 part
            const det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
            var s: Vec3(T) = undefined;
            s.x = @sqrt(a * a + d * d + g * g);
            if (det < 0) {
                // left handed matrix, flip sign
                s.x = -s.x;
            }
            s.y = @sqrt(b * b + e * e + h * h);
            s.z = @sqrt(c * c + f * f + i * i);

            // cancel out scale before extracting quaternion
            const inv_sx = 1 / s.x;
            const inv_sy = 1 / s.y;
            const inv_sz = 1 / s.z;
            a *= inv_sx;
            d *= inv_sx;
            g *= inv_sx;
            b *= inv_sy;
            e *= inv_sy;
            h *= inv_sy;
            c *= inv_sz;
            f *= inv_sz;
            i *= inv_sz;

            // shepards method
            const four_x_squared_minus1 = a - e - i;
            const four_y_squared_minus1 = e - a - i;
            const four_z_squared_minus1 = i - a - e;
            const four_w_squared_minus1 = a + e + i;
            var biggest_index: i32 = 0;
            var four_biggest_squared_minus1 = four_w_squared_minus1;
            if (four_x_squared_minus1 > four_biggest_squared_minus1) {
                four_biggest_squared_minus1 = four_x_squared_minus1;
                biggest_index = 1;
            }
            if (four_y_squared_minus1 > four_biggest_squared_minus1) {
                four_biggest_squared_minus1 = four_y_squared_minus1;
                biggest_index = 2;
            }
            if (four_z_squared_minus1 > four_biggest_squared_minus1) {
                four_biggest_squared_minus1 = four_z_squared_minus1;
                biggest_index = 3;
            }
            const biggest_val = @sqrt(four_biggest_squared_minus1 + 1) * 0.5;
            const mult = 0.25 / biggest_val;

            switch (biggest_index) {
                0 => {
                    return Self.init((h - f) * mult, (c - g) * mult, (d - b) * mult, biggest_val);
                },
                1 => {
                    return Self.init(biggest_val, (b + d) * mult, (g + c) * mult, (h - f) * mult);
                },
                2 => {
                    return Self.init((b + d) * mult, biggest_val, (f + h) * mult, (c - g) * mult);
                },
                3 => {
                    return Self.init((g + c) * mult, (f + h) * mult, biggest_val, (d - b) * mult);
                },
                else => unreachable,
            }
        }

        pub fn initVectors(from: Vec3(T), to: Vec3(T)) Self {
            const k = @sqrt(from.dot(from) * to.dot(to)); // |from| * |to|
            var w = k + from.dot(to);
            var v: Vec3(T) = undefined;

            if (w < 1e-6 * k) {
                // Antiparallel: rotate 180° around any axis perpendicular to `from`.
                w = 0;
                if (@abs(from.x) > @abs(from.z)) {
                    v = Vec3(T).init(-from.y, from.x, 0);
                } else {
                    v = Vec3(T).init(0, -from.z, from.y);
                }
            } else {
                v = from.cross(to);
            }

            const inv_len = 1 / @sqrt(v.dot(v) + w * w);
            return Self.init(v.x * inv_len, v.y * inv_len, v.z * inv_len, w * inv_len);
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.init(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self.init(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w);
        }

        pub fn neg(self: Self) Self {
            return Self.init(-self.x, -self.y, -self.z, -self.w);
        }

        pub fn mul(self: Self, other: Self) Self {
            return Self.init(
                self.x * other.w + self.y * other.z - self.z * other.y + self.w * other.x,
                -self.x * other.z + self.y * other.w + self.z * other.x + self.w * other.y,
                self.x * other.y - self.y * other.x + self.z * other.w + self.w * other.z,
                -self.x * other.x - self.y * other.y - self.z * other.z + self.w * other.w,
            );
        }

        pub fn mulScalar(self: Self, scalar: T) Self {
            return Self.init(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar);
        }

        pub fn divScalar(self: Self, scalar: T) Self {
            return Self.init(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar);
        }

        pub fn im(self: Self) Vec3(T) {
            return Vec3(T).init(self.x, self.y, self.z);
        }

        pub fn exp(self: Self) Self {
            const img = self.im();
            const angle = img.len();
            const s: T = if (angle > 0.0001) @sin(angle) / angle else 1.0;
            const n = img.mulScalar(s);
            return Self.init(n.x, n.y, n.z, @cos(angle));
        }

        pub fn log(self: Self) Self {
            const img = self.im();
            const s = img.len();
            const scale: T = if (s > 0.0001) std.math.atan2(s, self.w) / s else self.w;
            const v = img.mulScalar(scale);
            return Self.init(v.x, v.y, v.z, 0);
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
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

        pub fn conj(self: Self) Self {
            return Self.init(-self.x, -self.y, -self.z, self.w);
        }

        pub fn inverse(self: Self) Self {
            return self.unit().conj();
        }

        pub fn fuzzyEqual(self: Self, other: Self, eps: T) bool {
            const o = if (self.dot(other) < 0.0) other.neg() else other;
            return (@abs(self.x - o.x) <= eps and
                @abs(self.y - o.y) <= eps and
                @abs(self.z - o.z) <= eps and
                @abs(self.w - o.w) <= eps);
        }

        pub fn safeMix(self: Self, other: Self, alpha: T) Self {
            const t = std.math.clamp(alpha, 0.0, 1.0);
            const o = if (self.dot(other) < 0.0) other.neg() else other;
            return Self.init(
                std.math.lerp(self.x, o.x, t),
                std.math.lerp(self.y, o.y, t),
                std.math.lerp(self.z, o.z, t),
                std.math.lerp(self.w, o.w, t),
            );
        }

        pub fn nlerp(self: Self, other: Self, alpha: T) Self {
            return self.safeMix(other, alpha).safeUnit(other);
        }

        pub fn slerp(self: Self, other: Self, alpha: T) Self {
            var cos_theta = self.dot(other);

            // q and -q are the same rotation; flip one to take the shorter arc.
            const sign: T = if (cos_theta < 0) -1 else 1;
            cos_theta *= sign;

            // Default to plain lerp weights, used when the quats are nearly identical.
            var a: T = 1 - alpha;
            var b: T = alpha;
            if (cos_theta < 1 - 1e-6) {
                const theta = std.math.acos(cos_theta);
                const inv_sin = 1 / @sin(theta);
                a = @sin((1 - alpha) * theta) * inv_sin;
                b = @sin(alpha * theta) * inv_sin;
            }
            b *= sign;

            return Self.init(
                a * self.x + b * other.x,
                a * self.y + b * other.y,
                a * self.z + b * other.z,
                a * self.w + b * other.w,
            );
        }

        pub fn extractAxisAngle(self: Self) struct { Vec3(T), T } {
            const s = self.im().len(); // sin(angle/2)
            if (s < 1e-6) {
                // No rotation: axis is arbitrary.
                return .{ Vec3(T).init(1, 0, 0), 0 };
            }
            const angle = 2 * std.math.atan2(s, self.w);
            return .{ Vec3(T).init(self.x / s, self.y / s, self.z / s), angle };
        }

        pub fn extractSwingTwist(self: Self, twist_axis: Vec3(T)) struct { Self, Self } {
            const d = twist_axis.unit();

            // twist part has an axis (imaginary component) that is parallel to twist_axis argument.
            const axis_of_rot = self.im();
            const twist_im = d.mulScalar(d.dot(axis_of_rot));

            // and real compoent is relatively proportioanl to rotation's real component
            const twist = Quat(T).init(twist_im.x, twist_im.y, twist_im.z, self.w).unit();

            // once twist is knonw we can solve for wsing.
            // self = swing * rot -> swing = self * ~twist
            const swing = self.mul(twist.inverse());
            return .{ swing, twist };
        }

        pub fn rotate(self: Self, v: Vec3(T)) Vec3(T) {
            const q = self.mul(Self.init(v.x, v.y, v.z, 0.0)).mul(self.conj());
            return q.im();
        }
    };
}

test "Quat compiles" {
    std.testing.refAllDecls(Quat(f32));
}

test "Quat initAxisAngle" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Vec3f, f32 }{
        // ident
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(1, 0, 0), 0 },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), 0 },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), 0 },

        // 90, 180, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Vec3f.init(1, 0, 0), std.math.pi / 2.0 },
        .{ Quatf.init(1, 0, 0, 0), Vec3f.init(1, 0, 0), std.math.pi },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Vec3f.init(1, 0, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Vec3f.init(0, 1, 0), std.math.pi / 2.0 },
        .{ Quatf.init(0, 1, 0, 0), Vec3f.init(0, 1, 0), std.math.pi },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Vec3f.init(0, 1, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Vec3f.init(0, 0, 1), std.math.pi / 2.0 },
        .{ Quatf.init(0, 0, 1, 0), Vec3f.init(0, 0, 1), std.math.pi },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Vec3f.init(0, 0, 1), (3.0 * std.math.pi) / 2.0 },
    };

    for (cases) |case| {
        const expected, const axis, const angle = case;
        const actual = Quatf.initAxisAngle(axis, angle);
        const pass = expected.fuzzyEqual(actual, eps);
        if (!pass) {
            std.debug.print("case failed {any}, actual = {any}\n", .{ case, actual });
        }
        try std.testing.expect(pass);
    }
}

test "Quat initMat4" {
    const Vec3f = Vec3(f32);
    const Vec4f = Vec4(f32);
    const Mat4f = Mat4(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]Quatf{
        // ident
        Quatf.init(0, 0, 0, 1),

        // 90, 180, 270 rot about x
        Quatf.init(s2o2, 0, 0, s2o2),
        Quatf.init(1, 0, 0, 0),
        Quatf.init(s2o2, 0, 0, -s2o2),

        // 90, 180, 270 rot about y
        Quatf.init(0, s2o2, 0, s2o2),
        Quatf.init(0, 1, 0, 0),
        Quatf.init(0, s2o2, 0, -s2o2),

        // 90, 180, 270 rot about z
        Quatf.init(0, 0, s2o2, s2o2),
        Quatf.init(0, 0, 1, 0),
        Quatf.init(0, 0, s2o2, -s2o2),
    };

    for (cases) |case| {
        const expected = case;
        const x = case.rotate(Vec3f.x_axis);
        const y = case.rotate(Vec3f.y_axis);
        const z = case.rotate(Vec3f.z_axis);
        const m4 = Mat4f.init(Vec4f.initVec3(x, 0), Vec4f.initVec3(y, 0), Vec4f.initVec3(z, 0), Vec4f.init(0, 0, 0, 1));
        const actual = Quatf.initMat4(m4);
        const pass = expected.fuzzyEqual(actual, eps);
        if (!pass) {
            std.debug.print("case failed {any}, actual = {any}\n", .{ case, actual });
        }
        try std.testing.expect(pass);
    }
}

test "Quat initMat3" {
    const Vec3f = Vec3(f32);
    const Mat3f = Mat3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]Quatf{
        // ident
        Quatf.init(0, 0, 0, 1),

        // 90, 180, 270 rot about x
        Quatf.init(s2o2, 0, 0, s2o2),
        Quatf.init(1, 0, 0, 0),
        Quatf.init(s2o2, 0, 0, -s2o2),

        // 90, 180, 270 rot about y
        Quatf.init(0, s2o2, 0, s2o2),
        Quatf.init(0, 1, 0, 0),
        Quatf.init(0, s2o2, 0, -s2o2),

        // 90, 180, 270 rot about z
        Quatf.init(0, 0, s2o2, s2o2),
        Quatf.init(0, 0, 1, 0),
        Quatf.init(0, 0, s2o2, -s2o2),
    };

    for (cases) |case| {
        const expected = case;
        const x = case.rotate(Vec3f.x_axis);
        const y = case.rotate(Vec3f.y_axis);
        const z = case.rotate(Vec3f.z_axis);
        const m3 = Mat3f.init(x, y, z);
        const actual = Quatf.initMat3(m3);
        const pass = expected.fuzzyEqual(actual, eps);
        if (!pass) {
            std.debug.print("case failed {any}, actual = {any}\n", .{ case, actual });
        }
        try std.testing.expect(pass);
    }
}

test "Quat initVectors" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Vec3f, Vec3f }{
        // ident
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(1, 0, 0), Vec3f.init(1, 0, 0) },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), Vec3f.init(0, 1, 0) },

        // 90, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Vec3f.y_axis, Vec3f.z_axis },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Vec3f.y_axis, Vec3f.z_axis.neg() },

        // 90, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Vec3f.x_axis, Vec3f.z_axis.neg() },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Vec3f.x_axis, Vec3f.z_axis },

        // 90, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Vec3f.x_axis, Vec3f.y_axis },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Vec3f.x_axis, Vec3f.y_axis.neg() },
    };

    for (cases) |case| {
        const expected, const from, const to = case;
        const actual = Quatf.initVectors(from, to);
        const pass = expected.fuzzyEqual(actual, eps);
        if (!pass) {
            std.debug.print("case failed {any}, actual = {any}\n", .{ case, actual });
        }
        try std.testing.expect(pass);
    }
}

test "Quat add" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = Quatf.init(5.0, 6.0, 7.0, 8.0);
    const c = a.add(b);
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 8.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 10.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 12.0), c.w, 1e-5);
}

test "Quat sub" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = Quatf.init(5.0, 6.0, 7.0, 8.0);
    const c = a.sub(b);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.w, 1e-5);
}

test "Quat neg" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const c = a.neg();
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -2.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -3.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -4.0), c.w, 1e-5);
}

fn _testQuatMul(a: Quatf, b: Quatf) Quatf {
    return Quatf.init(
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    );
}

test "Quat mul" {
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]Quatf{
        // ident
        Quatf.init(0, 0, 0, 1),

        // 90, 180, 270 rot about x
        Quatf.init(s2o2, 0, 0, s2o2),
        Quatf.init(1, 0, 0, 0),
        Quatf.init(s2o2, 0, 0, -s2o2),

        // 90, 180, 270 rot about y
        Quatf.init(0, s2o2, 0, s2o2),
        Quatf.init(0, 1, 0, 0),
        Quatf.init(0, s2o2, 0, -s2o2),

        // 90, 180, 270 rot about z
        Quatf.init(0, 0, s2o2, s2o2),
        Quatf.init(0, 0, 1, 0),
        Quatf.init(0, 0, s2o2, -s2o2),
    };

    for (cases) |a| {
        for (cases) |b| {
            const expected = _testQuatMul(a, b);
            const actual = a.mul(b);
            const pass = expected.fuzzyEqual(actual, eps);
            if (!pass) {
                std.debug.print("case failed {any} * {any}, actual = {any}, expected = {any}\n", .{ a, b, actual, expected });
            }
            try std.testing.expect(pass);
        }
    }
}

test "Quat mulScalar" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = @as(f32, 5.0);
    const c = a.mulScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 10.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 15.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 20.0), c.w, 1e-5);
}

test "Quat divScalar" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = @as(f32, 5.0);
    const c = a.divScalar(b);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / 5.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / 5.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / 5.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / 5.0), c.w, 1e-5);
}

test "Quat im" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = a.im();
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), b.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), b.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), b.z, 1e-5);
}

test "Quat exp & log" {
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Quatf }{
        // ident
        .{ Quatf.init(0, 0, 0, 1), Quatf.init(0, 0, 0, 0) },

        // 90, 180, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Quatf.init(std.math.degreesToRadians(90) / 2.0, 0, 0, 0) },
        .{ Quatf.init(1, 0, 0, 0), Quatf.init(std.math.degreesToRadians(180) / 2.0, 0, 0, 0) },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Quatf.init(std.math.degreesToRadians(270) / 2.0, 0, 0, 0) },

        // 90, 180, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Quatf.init(0, std.math.degreesToRadians(90) / 2.0, 0, 0) },
        .{ Quatf.init(0, 1, 0, 0), Quatf.init(0, std.math.degreesToRadians(180) / 2.0, 0, 0) },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Quatf.init(0, std.math.degreesToRadians(270) / 2.0, 0, 0) },

        // 90, 180, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Quatf.init(0, 0, std.math.degreesToRadians(90) / 2.0, 0) },
        .{ Quatf.init(0, 0, 1, 0), Quatf.init(0, 0, std.math.degreesToRadians(180) / 2.0, 0) },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Quatf.init(0, 0, std.math.degreesToRadians(270) / 2.0, 0) },
    };

    for (cases) |case| {
        const q, const q_exp = case;
        const pass_log = q_exp.fuzzyEqual(q.log(), eps);
        const pass_exp = q.fuzzyEqual(q_exp.exp(), eps);
        if (!pass_log or !pass_exp) {
            std.debug.print("case failed {any}\n q_exp = {any}\n q_exp.exp() = {any}\n", .{ case, q.log(), q_exp.exp() });
        }
        try std.testing.expect(pass_log and pass_exp);
    }
}

test "Quat dot" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const b = Quatf.init(5.0, 6.0, 7.0, 8.0);
    const c = a.dot(b);
    try std.testing.expectApproxEqAbs(@as(f32, 70.0), c, 1e-5);
}

test "Quat len" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const len = a.len();
    try std.testing.expectApproxEqAbs(@as(f32, @sqrt(30.0)), len, 1e-5);
}

test "Quat unit" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const c = a.unit();
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(30.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(30.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / @sqrt(30.0)), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / @sqrt(30.0)), c.w, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);
}

test "Quat safeUnit" {
    const safe = Quatf.init(2.0, 0.0, 0.0, 0.0);
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const c = a.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0 / @sqrt(30.0)), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 / @sqrt(30.0)), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0 / @sqrt(30.0)), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0 / @sqrt(30.0)), c.w, 1e-5);
    try std.testing.expectApproxEqAbs(c.len(), 1.0, 1e-5);
    const b = Quatf.init(0, 0, 0, 0);
    const d = b.safeUnit(safe);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), d.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), d.w, 1e-5);
    try std.testing.expectApproxEqAbs(d.len(), 1.0, 1e-5);
}

test "Quat conj" {
    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);
    const c = a.conj();
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), c.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -2.0), c.y, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -3.0), c.z, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), c.w, 1e-5);
}

test "Quat inverse" {
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Quatf }{
        // ident
        .{ Quatf.init(0, 0, 0, 1), Quatf.init(0, 0, 0, 1) },

        // 90, 180, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Quatf.init(-s2o2, 0, 0, s2o2) },
        .{ Quatf.init(1, 0, 0, 0), Quatf.init(-1, 0, 0, 0) },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Quatf.init(-s2o2, 0, 0, -s2o2) },

        // 90, 180, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Quatf.init(0, -s2o2, 0, s2o2) },
        .{ Quatf.init(0, 1, 0, 0), Quatf.init(0, -1, 0, 0) },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Quatf.init(0, -s2o2, 0, -s2o2) },

        // 90, 180, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Quatf.init(0, 0, -s2o2, s2o2) },
        .{ Quatf.init(0, 0, 1, 0), Quatf.init(0, 0, -1, 0) },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Quatf.init(0, 0, -s2o2, -s2o2) },
    };

    for (cases) |case| {
        const q, const q_inv = case;
        const pass = q_inv.fuzzyEqual(q.inverse(), eps);
        if (!pass) {
            std.debug.print("case failed {any}\n", .{case});
        }
        try std.testing.expect(pass);
    }
}

test "Quat fuzzyEqual" {
    const eps = @as(f32, 0.0625);
    const small_eps = @as(f32, eps / 2.0);
    const large_eps = @as(f32, eps * 2.0);

    const a = Quatf.init(1.0, 2.0, 3.0, 4.0);

    const a_p_eps_x = a.add(Quatf.init(eps, 0.0, 0.0, 0.0));
    const a_s_eps_x = a.sub(Quatf.init(eps, 0.0, 0.0, 0.0));
    const a_p_eps_y = a.add(Quatf.init(0.0, eps, 0.0, 0.0));
    const a_s_eps_y = a.sub(Quatf.init(0.0, eps, 0.0, 0.0));
    const a_p_eps_z = a.add(Quatf.init(0.0, 0.0, eps, 0.0));
    const a_s_eps_z = a.sub(Quatf.init(0.0, 0.0, eps, 0.0));
    const a_p_eps_w = a.add(Quatf.init(0.0, 0.0, 0.0, eps));
    const a_s_eps_w = a.sub(Quatf.init(0.0, 0.0, 0.0, eps));

    const a_p_small_eps_x = a.add(Quatf.init(small_eps, 0.0, 0.0, 0.0));
    const a_s_small_eps_x = a.sub(Quatf.init(small_eps, 0.0, 0.0, 0.0));
    const a_p_small_eps_y = a.add(Quatf.init(0.0, small_eps, 0.0, 0.0));
    const a_s_small_eps_y = a.sub(Quatf.init(0.0, small_eps, 0.0, 0.0));
    const a_p_small_eps_z = a.add(Quatf.init(0.0, 0.0, small_eps, 0.0));
    const a_s_small_eps_z = a.sub(Quatf.init(0.0, 0.0, small_eps, 0.0));
    const a_p_small_eps_w = a.add(Quatf.init(0.0, 0.0, 0.0, small_eps));
    const a_s_small_eps_w = a.sub(Quatf.init(0.0, 0.0, 0.0, small_eps));

    const a_p_large_eps_x = a.add(Quatf.init(large_eps, 0.0, 0.0, 0.0));
    const a_s_large_eps_x = a.sub(Quatf.init(large_eps, 0.0, 0.0, 0.0));
    const a_p_large_eps_y = a.add(Quatf.init(0.0, large_eps, 0.0, 0.0));
    const a_s_large_eps_y = a.sub(Quatf.init(0.0, large_eps, 0.0, 0.0));
    const a_p_large_eps_z = a.add(Quatf.init(0.0, 0.0, large_eps, 0.0));
    const a_s_large_eps_z = a.sub(Quatf.init(0.0, 0.0, large_eps, 0.0));
    const a_p_large_eps_w = a.add(Quatf.init(0.0, 0.0, 0.0, large_eps));
    const a_s_large_eps_w = a.sub(Quatf.init(0.0, 0.0, 0.0, large_eps));

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

fn _testQuatSafeMix(a: Quatf, b: Quatf, alpha: f32) Quatf {
    const t = std.math.clamp(alpha, 0, 1);
    const b_flip = if (a.dot(b) < 0.0) b.neg() else b;
    return Quatf.init(
        std.math.lerp(a.x, b_flip.x, t),
        std.math.lerp(a.y, b_flip.y, t),
        std.math.lerp(a.z, b_flip.z, t),
        std.math.lerp(a.w, b_flip.w, t),
    );
}

test "Quat lerp" {
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]Quatf{
        // ident
        Quatf.init(0, 0, 0, 1),

        // 90, 180, 270 rot about x
        Quatf.init(s2o2, 0, 0, s2o2),
        Quatf.init(1, 0, 0, 0),
        Quatf.init(s2o2, 0, 0, -s2o2),

        // 90, 180, 270 rot about y
        Quatf.init(0, s2o2, 0, s2o2),
        Quatf.init(0, 1, 0, 0),
        Quatf.init(0, s2o2, 0, -s2o2),

        // 90, 180, 270 rot about z
        Quatf.init(0, 0, s2o2, s2o2),
        Quatf.init(0, 0, 1, 0),
        Quatf.init(0, 0, s2o2, -s2o2),
    };

    const alphas = [_]f32{ 0.0, 1.0, 0.5, 0.75, -0.25, 1.25 };

    for (cases) |a| {
        for (cases) |b| {
            for (alphas) |alpha| {
                const expected = _testQuatSafeMix(a, b, alpha);
                const actual = a.safeMix(b, alpha);
                const pass = expected.fuzzyEqual(actual, eps);
                if (!pass) {
                    std.debug.print("case failed {any}.lerp({any}, {any})\n, actual = {any}, expected = {any}\n", .{ a, b, alpha, actual, expected });
                }
                try std.testing.expect(pass);
            }
        }
    }
}

fn _testQuatNlerp(a: Quatf, b: Quatf, alpha: f32) Quatf {
    const t = std.math.clamp(alpha, 0, 1);
    const b_flip = if (a.dot(b) < 0.0) b.neg() else b;
    var r = Quatf.init(
        std.math.lerp(a.x, b_flip.x, t),
        std.math.lerp(a.y, b_flip.y, t),
        std.math.lerp(a.z, b_flip.z, t),
        std.math.lerp(a.w, b_flip.w, t),
    );

    const len = @sqrt(r.x * r.x + r.y * r.y + r.z * r.z + r.w * r.w);
    r.x /= len;
    r.y /= len;
    r.z /= len;
    r.w /= len;
    return r;
}

test "Quat nlerp" {
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]Quatf{
        // ident
        Quatf.init(0, 0, 0, 1),

        // 90, 180, 270 rot about x
        Quatf.init(s2o2, 0, 0, s2o2),
        Quatf.init(1, 0, 0, 0),
        Quatf.init(s2o2, 0, 0, -s2o2),

        // 90, 180, 270 rot about y
        Quatf.init(0, s2o2, 0, s2o2),
        Quatf.init(0, 1, 0, 0),
        Quatf.init(0, s2o2, 0, -s2o2),

        // 90, 180, 270 rot about z
        Quatf.init(0, 0, s2o2, s2o2),
        Quatf.init(0, 0, 1, 0),
        Quatf.init(0, 0, s2o2, -s2o2),
    };

    const alphas = [_]f32{ 0.0, 1.0, 0.5, 0.75, -0.25, 1.25 };

    for (cases) |a| {
        for (cases) |b| {
            for (alphas) |alpha| {
                const expected = _testQuatNlerp(a, b, alpha);
                const actual = a.nlerp(b, alpha);
                const pass = expected.fuzzyEqual(actual, eps);
                if (!pass) {
                    std.debug.print("case failed {any}.lerp({any}, {any})\n, actual = {any}, expected = {any}\n", .{ a, b, alpha, actual, expected });
                }
                try std.testing.expect(pass);
            }
        }
    }
}

test "Quat slerp" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Quatf, Quatf, Quatf, Quatf }{
        // a, b, slerp(1/4), slerp(1/2), slerp(3/4)
        .{ Quatf.init(0, 0, 0, 1), Quatf.init(s2o2, 0, 0, s2o2), Quatf.initAxisAngle(Vec3f.x_axis, std.math.degreesToRadians(22.5)), Quatf.initAxisAngle(Vec3f.x_axis, std.math.degreesToRadians(45)), Quatf.initAxisAngle(Vec3f.x_axis, std.math.degreesToRadians(67.5)) },
        .{ Quatf.init(0, 0, 0, 1), Quatf.init(0, s2o2, 0, s2o2), Quatf.initAxisAngle(Vec3f.y_axis, std.math.degreesToRadians(22.5)), Quatf.initAxisAngle(Vec3f.y_axis, std.math.degreesToRadians(45)), Quatf.initAxisAngle(Vec3f.y_axis, std.math.degreesToRadians(67.5)) },
        .{ Quatf.init(0, 0, 0, 1), Quatf.init(0, 0, s2o2, s2o2), Quatf.initAxisAngle(Vec3f.z_axis, std.math.degreesToRadians(22.5)), Quatf.initAxisAngle(Vec3f.z_axis, std.math.degreesToRadians(45)), Quatf.initAxisAngle(Vec3f.z_axis, std.math.degreesToRadians(67.5)) },
    };

    for (cases) |case| {
        const a, const b, const one_quarter, const one_half, const three_quarters = case;
        const actual_one_quarter = a.slerp(b, 0.25);
        const actual_one_half = a.slerp(b, 0.5);
        const actual_three_quarters = a.slerp(b, 0.75);

        const pass1 = one_quarter.fuzzyEqual(actual_one_quarter, eps);
        if (!pass1) {
            std.debug.print("case failed {any}slerp({any}, {any})\n, actual = {any}, expected = {any}\n len = {any}\n", .{ a, b, 0.25, actual_one_quarter, one_quarter, actual_one_quarter.len() });
        }
        const pass2 = one_half.fuzzyEqual(actual_one_half, eps);
        const pass3 = three_quarters.fuzzyEqual(actual_three_quarters, eps);

        try std.testing.expect(pass1 and pass2 and pass3);
    }
}

test "Quat extractSwingTwist" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Vec3f, f32 }{
        // 90, 180, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Vec3f.init(1, 0, 0), std.math.pi / 2.0 },
        .{ Quatf.init(1, 0, 0, 0), Vec3f.init(1, 0, 0), std.math.pi },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Vec3f.init(1, 0, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Vec3f.init(0, 1, 0), std.math.pi / 2.0 },
        .{ Quatf.init(0, 1, 0, 0), Vec3f.init(0, 1, 0), std.math.pi },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Vec3f.init(0, 1, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Vec3f.init(0, 0, 1), std.math.pi / 2.0 },
        .{ Quatf.init(0, 0, 1, 0), Vec3f.init(0, 0, 1), std.math.pi },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Vec3f.init(0, 0, 1), (3.0 * std.math.pi) / 2.0 },
    };

    for (cases) |case| {
        const q, const axis, const angle = case;
        const swing, const twist = q.extractSwingTwist(axis);
        const combined = swing.mul(twist);
        const pass1 = q.fuzzyEqual(combined, eps);
        const pass2 = swing.fuzzyEqual(Quatf.identity, eps);
        if (!pass2) {
            std.debug.print("case failed {any}, swing = {any}, twist = {any}\n", .{ case, swing, twist });
        }

        const pass3 = twist.fuzzyEqual(Quatf.initAxisAngle(axis, angle), eps);

        try std.testing.expect(pass1 and pass2 and pass3);
    }
}

test "Quat extractAxisAngle" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Vec3f, f32 }{
        // 90, 180, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Vec3f.init(1, 0, 0), std.math.pi / 2.0 },
        .{ Quatf.init(1, 0, 0, 0), Vec3f.init(1, 0, 0), std.math.pi },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Vec3f.init(1, 0, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Vec3f.init(0, 1, 0), std.math.pi / 2.0 },
        .{ Quatf.init(0, 1, 0, 0), Vec3f.init(0, 1, 0), std.math.pi },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Vec3f.init(0, 1, 0), (3.0 * std.math.pi) / 2.0 },

        // 90, 180, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Vec3f.init(0, 0, 1), std.math.pi / 2.0 },
        .{ Quatf.init(0, 0, 1, 0), Vec3f.init(0, 0, 1), std.math.pi },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Vec3f.init(0, 0, 1), (3.0 * std.math.pi) / 2.0 },
    };

    for (cases) |case| {
        const q, const expected_axis, const expected_angle = case;
        const actual_axis, const actual_angle = q.extractAxisAngle();
        const pos_same = actual_axis.fuzzyEqual(expected_axis, eps) and @abs(actual_angle - expected_angle) <= eps;
        const neg_same = actual_axis.fuzzyEqual(expected_axis.neg(), eps) and @abs(actual_angle + expected_angle) <= eps;
        if (pos_same == neg_same) {
            std.debug.print("case failed {any}, actual_axis = {any}, actual_angle = {any}\n", .{ case, actual_axis, actual_angle });
        }
        try std.testing.expect(pos_same != neg_same);
    }
}

test "Quat rotate" {
    const Vec3f = Vec3(f32);
    const eps: f32 = 0.0001;
    const s2o2: f32 = @sqrt(2.0) / 2.0;
    const cases = [_]struct { Quatf, Vec3f, Vec3f }{
        // ident
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(1, 0, 0), Vec3f.init(1, 0, 0) },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), Vec3f.init(0, 1, 0) },

        // 90, 270 rot about x
        .{ Quatf.init(s2o2, 0, 0, s2o2), Vec3f.y_axis, Vec3f.z_axis },
        .{ Quatf.init(s2o2, 0, 0, -s2o2), Vec3f.y_axis, Vec3f.z_axis.neg() },

        // 90, 270 rot about y
        .{ Quatf.init(0, s2o2, 0, s2o2), Vec3f.x_axis, Vec3f.z_axis.neg() },
        .{ Quatf.init(0, s2o2, 0, -s2o2), Vec3f.x_axis, Vec3f.z_axis },

        // 90, 270 rot about z
        .{ Quatf.init(0, 0, s2o2, s2o2), Vec3f.x_axis, Vec3f.y_axis },
        .{ Quatf.init(0, 0, s2o2, -s2o2), Vec3f.x_axis, Vec3f.y_axis.neg() },
    };
    for (cases) |case| {
        const q, const from, const to = case;
        const actual_to = q.rotate(from);
        try std.testing.expect(actual_to.fuzzyEqual(to, eps));
    }
}
