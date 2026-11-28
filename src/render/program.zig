const std = @import("std");
const math = @import("../math/root.zig");
const Vec2f = math.Vec2f;
const Vec3f = math.Vec3f;
const Vec4f = math.Vec4f;
const Mat3f = math.Mat3f;
const Mat4f = math.Mat4f;
const util = @import("util.zig");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

pub const Program = struct {
    const Self = @This();

    const Variable = struct {
        size: gl.Int,
        type: gl.Uint,
        loc: gl.Int,
    };

    const Source = struct {
        vert: []const u8,
        frag: []const u8,
        geom: ?[]const u8 = null,
    };

    allocator: std.mem.Allocator,
    prog: gl.Uint = 0,
    vert_shader: gl.Uint = 0,
    geom_shader: gl.Uint = 0,
    frag_shader: gl.Uint = 0,

    uniform_map: std.StringHashMap(Variable),
    attrib_map: std.StringHashMap(Variable),
    macros: std.StringHashMap([]const u8),

    pub fn create(allocator: std.mem.Allocator, src: Source) !*Self {
        const self = try allocator.create(Program);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .uniform_map = std.StringHashMap(Variable).init(allocator),
            .attrib_map = std.StringHashMap(Variable).init(allocator),
            .macros = std.StringHashMap([]const u8).init(allocator),
        };

        self.vert_shader = try util.compile_shader(src.vert, gl.VERTEX_SHADER);
        errdefer gl.deleteShader(self.vert_shader);

        self.frag_shader = try util.compile_shader(src.frag, gl.FRAGMENT_SHADER);
        errdefer gl.deleteShader(self.frag_shader);

        if (src.geom) |s| {
            self.geom_shader = try util.compile_shader(s, gl.GEOMETRY_SHADER);
            errdefer gl.deleteShader(self.geom_shader);
        }

        self.prog = gl.createProgram();
        if (self.prog == 0) {
            return error.CreateProgramFailed;
        }
        errdefer gl.deleteProgram(self.prog);

        gl.attachShader(self.prog, self.vert_shader);
        gl.attachShader(self.prog, self.frag_shader);
        if (self.geom_shader > 0) {
            gl.attachShader(self.prog, self.geom_shader);
        }

        gl.linkProgram(self.prog);

        var linked: gl.Int = gl.FALSE;
        gl.getProgramiv(self.prog, gl.LINK_STATUS, &linked);

        var str_buf: [1024]u8 = undefined;
        var str_len: gl.Sizei = 0;

        if (linked == gl.FALSE) {
            gl.getProgramInfoLog(self.prog, str_buf.len, &str_len, &str_buf);
            std.log.err("program link failed:\n{s}", .{str_buf[0..@intCast(str_len)]});
            return error.ProgramLinkFailed;
        }

        var num_uniforms: gl.Int = undefined;
        gl.getProgramiv(self.prog, gl.ACTIVE_UNIFORMS, &num_uniforms);
        std.log.info("uniforms", .{});
        const uniform_count: usize = @intCast(num_uniforms);
        for (0..uniform_count) |i| {
            var var_size: gl.Int = undefined;
            var var_type: gl.Uint = undefined;
            gl.getActiveUniform(self.prog, @intCast(i), str_buf.len, &str_len, &var_size, &var_type, &str_buf);
            const var_loc: gl.Int = gl.getUniformLocation(self.prog, &str_buf);
            const name = try self.allocator.dupe(u8, str_buf[0..@intCast(str_len)]);
            errdefer self.allocator.free(name);
            std.log.info("    {s}: {any}", .{ name, var_loc });
            try self.uniform_map.put(name, .{ .size = var_size, .type = var_type, .loc = var_loc });
        }

        var num_attribs: gl.Int = undefined;
        gl.getProgramiv(self.prog, gl.ACTIVE_ATTRIBUTES, &num_attribs);
        std.log.info("attribs", .{});
        const attrib_count: usize = @intCast(num_attribs);
        for (0..attrib_count) |i| {
            var var_size: gl.Int = undefined;
            var var_type: gl.Uint = undefined;
            gl.getActiveAttrib(self.prog, @intCast(i), str_buf.len, &str_len, &var_size, &var_type, &str_buf);
            const name = try self.allocator.dupe(u8, str_buf[0..@intCast(str_len)]);
            errdefer self.allocator.free(name);
            const var_loc: gl.Int = gl.getAttribLocation(self.prog, &str_buf);
            std.log.info("    {s}: {any}", .{ name, var_loc });
            try self.attrib_map.put(name, .{ .size = var_size, .type = var_type, .loc = var_loc });
        }

        util.checkError("Program.create");
        return self;
    }

    pub fn destroy(self: *Self) void {
        var it = self.uniform_map.keyIterator();
        while (it.next()) |key| self.allocator.free(key.*);
        self.uniform_map.deinit();

        it = self.attrib_map.keyIterator();
        while (it.next()) |key| self.allocator.free(key.*);
        self.attrib_map.deinit();

        self.macros.deinit();

        gl.deleteShader(self.vert_shader);
        gl.deleteShader(self.geom_shader);
        gl.deleteShader(self.frag_shader);
        gl.deleteProgram(self.prog);

        self.allocator.destroy(self);
    }

    pub fn setUniformFloat(self: Self, name: []const u8, value: f32) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix1f(u.loc, 1, value);
        } else {
            return error.UniformNotFound;
        }
    }

    pub fn setUniformVec2f(self: Self, name: []const u8, value: Vec2f) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix2fv(u.loc, 1, @ptrCast(&value));
        } else {
            return error.UniformNotFound;
        }
    }

    pub fn setUniformVec3f(self: Self, name: []const u8, value: Vec3f) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix3fv(u.loc, 1, @ptrCast(&value));
        } else {
            return error.UniformNotFound;
        }
    }

    pub fn setUniformVec4f(self: Self, name: []const u8, value: Vec4f) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix4fv(u.loc, 1, @ptrCast(&value));
        } else {
            return error.UniformNotFound;
        }
    }

    pub fn setUniformMat3f(self: Self, name: []const u8, value: Mat3f) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix3fv(u.loc, 1, gl.FALSE, @ptrCast(&value));
        } else {
            return error.UniformNotFound;
        }
    }

    pub fn setUniformMat4f(self: Self, name: []const u8, value: Mat4f) !void {
        if (self.uniform_map.get(name)) |u| {
            gl.uniformMatrix4fv(u.loc, 1, gl.FALSE, @ptrCast(&value));
        } else {
            return error.UniformNotFound;
        }
    }
};
