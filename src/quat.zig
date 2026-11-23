const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Mat3 = @import("mat3.zig").Mat3;
const Mat4 = @import("mat4.zig").Mat4;

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
            const s: T = if (angle > 0.0001) @sin(angle / 2) / angle else 0.5;
            const n = img.mulScalar(s);
            return Self.init(n.x, n.y, n.z, @cos(angle / 2));
        }

        pub fn log(self: Self) Self {
            const img = self.im();
            const s = img.len();
            const scale: T = if (s > 0.0001) 2.0 * std.math.atan2(s, self.w) / s else 2.0 / self.w;
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

        pub fn lerp(self: Self, other: Self, alpha: T) Self {
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
            return self.lerp(other, alpha).safeUnit(other);
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
            const twist = Quat(T).init(self.w, twist_im.x, twist_im.y, twist_im.z).unit();

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
    const cases = [_]struct { Quatf, Vec3f, f32 }{
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(1, 0, 0), 0 },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), 0 },
        .{ Quatf.init(0, 0, 0, 1), Vec3f.init(0, 1, 0), 0 },
    };

    for (cases) |case| {
        const q, const axis, const angle = case;
        const pass = q.fuzzyEqual(Quatf.initAxisAngle(axis, angle), eps);
        if (!pass) {
            std.debug.print("case failed {any}\n", .{case});
        }
        try std.testing.expect(pass);
    }
}

test "Quat initMat4" {}

test "Quat initMat3" {}

test "Quat initVectors" {}

test "Quat add" {}

test "Quat sub" {}

test "Quat neg" {}

test "Quat mul" {}

test "Quat mulScalar" {}

test "Quat divScalar" {}

test "Quat im" {}

test "Quat exp" {}

test "Quat log" {}

test "Quat dot" {}

test "Quat len" {}

test "Quat unit" {}

test "Quat safeUnit" {}

test "Quat conj" {}

test "Quat inverse" {}

test "Quat fuzzyEqual" {}

test "Quat lerp" {}

test "Quat nlerp" {}

test "Quat slerp" {}

test "Quat extractSwingTwist" {}

test "Quat extractAxisAngle" {}

test "Quat rotate" {}
