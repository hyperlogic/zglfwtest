const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Mat3 = @import("mat3.zig").Mat3;
const Mat4 = @import("mat4.zig").Mat4;

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
            _ = m;
            @compileError("implemented");
        }

        pub fn initMat3(m: Mat3(T)) Self {
            _ = m;
            @compileError("not implemented");
        }

        pub fn initVectors(from: Vec3(T), to: Vec3(T)) Self {
            _ = .{ from, to };
            @compileError("not implemented");
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
