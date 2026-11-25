const std = @import("std");
const Quat = @import("quat.zig").Quat;
const Vec3 = @import("vec3.zig").Vec3;

pub const Xformf = Xform(f32);
pub const Xformd = Xform(f64);

pub fn Xform(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Xform is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return struct {
        const Self = @This();

        trans: Vec3(T),
        rot: Quat(T),
        scale: T,

        pub fn init(trans: Vec3(T), rot: Quat(T), scale: T) Self {
            return Self{ .trans = trans, .rot = rot, .scale = scale };
        }

        pub fn initRot(rot: Quat(T)) Self {
            return Self.init(Vec3(T).zero, rot, 1.0);
        }

        pub fn initRotScale(rot: Quat(T), scale: T) Self {
            return Self.init(Vec3(T).zero, rot, scale);
        }

        pub fn initTrans(trans: Vec3(T)) Self {
            return Self.init(trans, Quat(T).indentity, 1.0);
        }

        pub fn initTransScale(trans: Vec3(T), scale: T) Self {
            return Self.init(trans, Quat(T).identity, scale);
        }

        pub fn initTransRot(trans: Vec3(T), rot: Quat(T)) Self {
            return Self.init(trans, rot, 1.0);
        }
    };
}
