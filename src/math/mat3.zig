const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;
const Quat = @import("quat.zig").Quat;

pub const Mat3f = Mat3(f32);
pub const Mat3d = Mat3(f64);

pub fn Mat3(comptime T: type) type {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .float => {},
        else => @compileError("Mat3 is only defined for floating point types. Type '" ++ @typeName(T) ++ "' is not supported."),
    }

    return extern struct {
        const Self = @This();

        // column vectors
        x: Vec3(T),
        y: Vec3(T),
        z: Vec3(T),

        pub const identity = Self.init(
            Vec3(T).init(1, 0, 0),
            Vec3(T).init(0, 1, 0),
            Vec3(T).init(0, 0, 1),
        );

        pub fn init(x: Vec3(T), y: Vec3(T), z: Vec3(T)) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn initRot(r: Quat(T)) Self {
            const x = r.rotate(Vec3(T).x_axis);
            const y = r.rotate(Vec3(T).y_axis);
            const z = r.rotate(Vec3(T).z_axis);
            return Self.init(x, y, z);
        }

        pub fn initRotScale(r: Quat(T), s: Vec3(T)) Self {
            const x = r.rotate(Vec3(T).x_axis).mulScalar(s.x);
            const y = r.rotate(Vec3(T).y_axis).mulScalar(s.y);
            const z = r.rotate(Vec3(T).z_axis).mulScalar(s.z);
            return Self.init(x, y, z);
        }

        pub fn initRotUniformScale(r: Quat(T), s: T) Self {
            const x = r.rotate(Vec3(T).x_axis).mulScalar(s);
            const y = r.rotate(Vec3(T).y_axis).mulScalar(s);
            const z = r.rotate(Vec3(T).z_axis).mulScalar(s);
            return Self.init(x, y, z);
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

        pub fn mul(self: Self, other: Self) Self {
            const r0 = self.extractRow0();
            const r1 = self.extractRow1();
            const r2 = self.extractRow2();
            return Self.init(
                Vec3(T).init(r0.dot(other.x), r1.dot(other.x), r2.dot(other.x)),
                Vec3(T).init(r0.dot(other.y), r1.dot(other.y), r2.dot(other.y)),
                Vec3(T).init(r0.dot(other.z), r1.dot(other.z), r2.dot(other.z)),
            );
        }

        pub fn extractRot(self: Self) Quat(T) {
            return Quat(T).initMat3(self);
        }

        pub fn extractScale(self: Self) Vec3(T) {
            return Vec3(T).init(self.x.len(), self.y.len(), self.z.len());
        }

        pub fn extractRotScale(self: Self) struct { Quat(T), Vec3(T) } {
            return .{ self.extractRot(), self.extractScale() };
        }

        pub fn extractRow0(self: Self) Vec3(T) {
            return Vec3(T).init(self.x.x, self.y.x, self.z.x);
        }

        pub fn extractRow1(self: Self) Vec3(T) {
            return Vec3(T).init(self.x.y, self.y.y, self.z.y);
        }

        pub fn extractRow2(self: Self) Vec3(T) {
            return Vec3(T).init(self.x.z, self.y.z, self.z.z);
        }

        pub fn xform(self: Self, v: Vec3(T)) Vec3(T) {
            const r0 = self.extractRow0();
            const r1 = self.extractRow1();
            const r2 = self.extractRow2();
            return Vec3(T).init(r0.dot(v), r1.dot(v), r2.dot(v));
        }

        pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("({f}, {f}, {f})", .{ self.x, self.y, self.z });
        }
    };
}

test "Mat3 compiles" {
    std.testing.refAllDecls(Mat3(f32));
}
