const std = @import("std");
const vec3 = @import("vec3.zig");

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

        pub fn init(x: T, y: T, z: T, w: T) Self {
            return Self{ .x = x, .y = y, .z = z, .w = w };
        }

        pub fn initAxisAngle(axis: vec3.Vec3(T), angle: T) Self {
            const l = axis.len();
            const n = axis.mulScalar(@sin(angle / 2.0) / l);
            const w = @cos(angle / 2.0);
            return Self.init(n.x, n.y, n.z, w);
        }

        pub fn ident() Self {
            return Self.init(0.0, 0.0, 0.0, 1.0);
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.init(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self.init(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w);
        }

        pub fn mul(self: Self, other: Self) Self {
            const x = self.x * other.w + self.y * other.z - self.z * other.y + self.w * other.x;
            const y = -self.x * other.z + self.y * other.w + self.z * other.x + self.w * other.y;
            const z = self.x * other.y - self.y * other.x + self.z * other.w + self.w * other.z;
            const w = -self.x * other.x - self.y * other.y - self.z * other.z + self.w * other.w;
            return Self.init(x, y, z, w);
        }

        pub fn mulScalar(self: Self, scalar: T) Self {
            return Self.init(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar);
        }

        pub fn divScalar(self: Self, scalar: T) Self {
            return Self.init(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar);
        }

        pub fn im(self: Self) vec3.Vec3(T) {
            return vec3.Vec3(T).init(self.x, self.y, self.z);
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
            return @abs(self.x - other.x) <= eps and @abs(self.y - other.y) <= eps and @abs(self.z - other.z) <= eps and @abs(self.w - other.w) <= eps;
        }
    };
}

test "Quat compiles" {
    std.testing.refAllDecls(Quat(f32));
}
