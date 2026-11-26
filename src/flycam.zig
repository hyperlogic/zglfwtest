const std = @import("std");
const math = @import("math/root.zig");

const Mat4f = math.Mat4f;
const Quatf = math.Quatf;
const Vec2f = math.Vec2f;
const Vec3f = math.Vec3f;
const Vec4f = math.Vec4f;

pub const FlyCam = struct {
    const Self = @This();

    camera_mat: Mat4f,
    world_up: Vec3f,
    pos: Vec3f,
    vel: Vec3f,
    rot: Quatf,
    speed: f32,
    rot_speed: f32,

    const rise_time: f32 = 0.1; // time to reach ~95% of terminal speed

    pub fn init(world_up: Vec3f, pos: Vec3f, rot: Quatf, speed: f32, rot_speed: f32) Self {
        return Self{
            .camera_mat = Mat4f.initTransRot(pos, rot),
            .world_up = world_up,
            .pos = pos,
            .vel = Vec3f.zero,
            .rot = rot,
            .speed = speed,
            .rot_speed = rot_speed,
        };
    }

    pub fn process(self: *Self, left_stick: Vec2f, right_stick: Vec2f, roll_amount: f32, up_amount: f32, dt: f32) void {
        const l_stick = left_stick.clampLen(1.0);
        const r_stick = right_stick.clampLen(1.0);

        const k = 3.0 / Self.rise_time;
        const k_exp = std.math.exp(-k * dt);

        const target_vel = self.rot.rotate(Vec3f.init(l_stick.x, up_amount, -l_stick.y).mulScalar(self.speed));
        const v = self.vel.mulScalar(k_exp).add(target_vel.mulScalar(1 - k_exp));
        self.pos = self.pos.add(self.vel.sub(target_vel).mulScalar((1 - k_exp) / k).add(target_vel.mulScalar(dt)));
        self.vel = v;

        const right = self.rot.rotate(Vec3f.x_axis);
        const forward = self.rot.rotate(Vec3f.z_axis.neg());
        const yaw = Quatf.initAxisAngle(self.world_up, self.rot_speed * dt * -r_stick.x);
        const pitch = Quatf.initAxisAngle(right, self.rot_speed * dt * r_stick.y);
        self.rot = yaw.mul(pitch).mul(self.rot);

        const x = self.rot.rotate(Vec3f.x_axis);
        const y = self.rot.rotate(Vec3f.y_axis);
        const z = self.rot.rotate(Vec3f.z_axis);

        if (@abs(roll_amount) > 0.1) {
            self.world_up = Vec3f.initVec4(self.camera_mat.y);
            const roll = Quatf.initAxisAngle(forward, self.rot_speed * dt * roll_amount);
            self.world_up = roll.rotate(self.world_up);
        }

        if (z.dot(self.world_up) < 0.999) {
            const xx = self.world_up.cross(z).unit();
            const yy = z.cross(xx).unit();
            self.camera_mat = Mat4f.init(
                Vec4f.initVec3(xx, 0),
                Vec4f.initVec3(yy, 0),
                Vec4f.initVec3(z, 0),
                Vec4f.initVec3(self.pos, 1),
            );
        } else {
            self.camera_mat = Mat4f.init(
                Vec4f.initVec3(x, 0),
                Vec4f.initVec3(y, 0),
                Vec4f.initVec3(z, 0),
                Vec4f.initVec3(self.pos, 1),
            );
        }
        self.rot = self.camera_mat.extractRot();
    }
};
