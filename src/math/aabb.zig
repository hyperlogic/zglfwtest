const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;

pub const Aabbf = Aabb(f32);
pub const Aabbd = Aabb(f64);

pub fn Aabb(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Aabb is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        min: Vec3(T),
        max: Vec3(T),

        pub fn init(min: Vec3(T), max: Vec3(T)) Self {
            return Self{ .min = min, .max = max };
        }

        pub fn initEmpty() Self {
            const inf = std.math.inf(T);
            return Self.init(Vec3(T).splat(inf), Vec3(T).splat(-inf));
        }

        pub fn contains(self: Self, p: Vec3(T)) bool {
            return (p.x >= self.min.x and p.x <= self.max.x) and
                (p.y >= self.min.y and p.y <= self.max.y) and
                (p.z >= self.min.z and p.z <= self.max.z);
        }
    };
}
