const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Vec4 = @import("vec4.zig").Vec4;
const Quat = @import("quat.zig").Quat;

pub fn Mat4(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Mat3 is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        // column vectors
        x: Vec4(T),
        y: Vec4(T),
        z: Vec4(T),
        w: Vec4(T),

        pub fn init(x: Vec4(T), y: Vec4(T), z: Vec4(T), w: Vec4(T)) Self {
            return Self{ .x = x, .y = y, .z = z, .w = w };
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
                Vec4(T).init(s.x, 0.0, 0.0, 0.0),
                Vec4(T).init(0.0, s.y, 0.0, 0.0),
                Vec4(T).init(0.0, 0.0, s.z, 0.0),
                Vec4(T).init(0.0, 0.0, 0.0, 1.0),
            );
        }

        pub fn initTrans(t: Vec3(T)) Self {
            return initTransScale(t, Vec3(T).init(1.0, 1.0, 1.0));
        }

        pub fn initTransRot(t: Vec3(T), r: Quat(T)) Self {
            return initTransRotScale(t, r, Vec3(T).init(1.0, 1.0, 1.0));
        }

        pub fn initTransRotScale(t: Vec3(T), r: Quat(T), s: Vec3(T)) Self {
            _ = .{ t, r, s };
            @compileError("not implemented");
        }

        pub fn initTransRotUniformScale(t: Vec3(T), r: Quat(T), s: T) Self {
            _ = .{ t, r, s };
            @compileError("not implemented");
        }

        pub fn initTransScale(t: Vec3(T), s: Vec3(T)) Self {
            return Self.init(
                Vec4(T).init(s.x, 0.0, 0.0, 0.0),
                Vec4(T).init(0.0, s.y, 0.0, 0.0),
                Vec4(T).init(0.0, 0.0, s.z, 0.0),
                Vec4(T).init(t.x, t.y, t.z, 1.0),
            );
        }

        pub fn initUniformScale(s: T) Self {
            return Self.initScale(Vec3(T).init(s, s, s));
        }

        pub fn extractTrans(self: Self) Vec3(T) {
            return Vec3(T).init(self.w.x, self.w.y, self.w.z);
        }

        pub fn extractRot(self: Self) Quat(T) {
            return Quat(T).initMat4(self);
        }

        pub fn extractScale(self: Self) Vec3(T) {
            _ = self;
            @compileError("not implemented");
        }

        pub fn extractTransRotScale(self: Self) struct { Vec3(T), Quat(T), Vec3(T) } {
            return .{ self.extractTrans(), self.extractRot(), self.extractScale() };
        }
    };
}

test "Mat4 compiles" {
    std.testing.refAllDecls(Mat4(f32));
}
