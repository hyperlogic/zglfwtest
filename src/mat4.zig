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

        pub const identity = Self.init(
            Vec4(T).init(1, 0, 0, 0),
            Vec4(T).init(0, 1, 0, 0),
            Vec4(T).init(0, 0, 1, 0),
            Vec4(T).init(0, 0, 0, 1),
        );

        pub fn init(x: Vec4(T), y: Vec4(T), z: Vec4(T), w: Vec4(T)) Self {
            return Self{ .x = x, .y = y, .z = z, .w = w };
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

        pub fn mul(self: Self, other: Self) Self {
            const r0 = self.extractRow0();
            const r1 = self.extractRow1();
            const r2 = self.extractRow2();
            const r3 = self.extractRow3();
            return Self.init(
                Vec4(T).init(r0.dot(other.x), r0.dot(other.y), r0.dot(other.z), r0.dot(other.w)),
                Vec4(T).init(r1.dot(other.x), r1.dot(other.y), r1.dot(other.z), r1.dot(other.w)),
                Vec4(T).init(r2.dot(other.x), r2.dot(other.y), r2.dot(other.z), r2.dot(other.w)),
                Vec4(T).init(r3.dot(other.x), r3.dot(other.y), r3.dot(other.z), r3.dot(other.w)),
            );
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

        pub fn extractRow0(self: Self) Vec4(T) {
            return Vec4(T).init(self.x.x, self.y.x, self.z.x, self.w.x);
        }

        pub fn extractRow1(self: Self) Vec4(T) {
            return Vec4(T).init(self.x.y, self.y.y, self.z.y, self.w.y);
        }

        pub fn extractRow2(self: Self) Vec4(T) {
            return Vec4(T).init(self.x.z, self.y.z, self.z.z, self.w.z);
        }

        pub fn extractRow3(self: Self) Vec4(T) {
            return Vec4(T).init(self.x.w, self.y.w, self.z.w, self.w.w);
        }

        pub fn xformPoint(self: Self, p: Vec3(T)) Vec3(T) {
            const r0 = self.extractRow0();
            const r1 = self.extractRow1();
            const r2 = self.extractRow2();
            const r3 = self.extractRow3();
            const v = Vec4(T).init(p.x, p.y, p.z, 1.0);
            const result = Vec4(T).init(r0.dot(v), r1.dot(v), r2.dot(v), r3.dot(v));
            return Vec3(T).init(result.x / result.w, result.y / result.w, result.z / result.w);
        }

        pub fn xformPointOrtho(self: Self, p: Vec3(T)) Vec3(T) {
            const r0 = Vec3(T).init(self.x.x, self.y.x, self.z.x);
            const r1 = Vec3(T).init(self.x.y, self.y.y, self.z.y);
            const r2 = Vec3(T).init(self.x.z, self.y.z, self.z.z);
            const result = Vec3(T).init(r0.dot(p) + self.w.x, r1.dot(p) + self.w.y, r2.dot(p) + self.w.z);
            return result;
        }

        pub fn xformVec(self: Self, v: Vec3(T)) Vec3(T) {
            const r0 = Vec3(T).init(self.x.x, self.y.x, self.z.x);
            const r1 = Vec3(T).init(self.x.y, self.y.y, self.z.y);
            const r2 = Vec3(T).init(self.x.z, self.y.z, self.z.z);
            const result = Vec3(T).init(r0.dot(v), r1.dot(v), r2.dot(v));
            return result;
        }
    };
}

test "Mat4 compiles" {
    std.testing.refAllDecls(Mat4(f32));
}
