const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Quat = @import("quat.zig").Quat;

pub fn Mat3(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Mat3 is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        // column vectors
        x: Vec3(T),
        y: Vec3(T),
        z: Vec3(T),

        pub fn init(x: Vec3(T), y: Vec3(T), z: Vec3(T)) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn initIdent() Self {
            return Self.initUniformScale(1.0);
        }

        pub fn initRot(r: Quat(T)) Self {
            _ = r;
            @compileError("not implemented");
        }

        pub fn initRotScale(r: Quat(T), s: Vec3(T)) Self {
            _ = .{ r, s };
            @compileError("not implemented");
        }

        pub fn initRotUniformScale(r: Quat(T), s: T) Self {
            _ = .{ r, s };
            @compileError("not implemented");
        }

        pub fn initScale(s: Vec3(T)) Self {
            return Self.init(
                Vec3(T).init(s.x, 0.0, 0.0),
                Vec3(T).init(0.0, s.y, 0.0),
                Vec3(T).init(0.0, 0.0, s.z),
            );
        }

        pub fn initUniformScale(s: T) Self {
            return Self.initScale(Vec3(T).init(s, s, s));
        }
    };
}

test "Mat3 compiles" {
    std.testing.refAllDecls(Mat3(f32));
}
