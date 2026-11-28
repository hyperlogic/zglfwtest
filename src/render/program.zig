const std = @import("std");
const math = @import("../math/root.zig");
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

        if (linked == gl.FALSE) {
            var log_buf: [1024]u8 = undefined;
            var log_len: gl.Sizei = 0;
            gl.getProgramInfoLog(self.prog, log_buf.len, &log_len, &log_buf);
            std.log.err("program link failed:\n{s}", .{log_buf[0..@intCast(log_len)]});
            return error.ProgramLinkFailed;
        }

        util.checkError("Program.create");
        return self;
    }

    pub fn destroy(self: *Self) void {
        self.uniform_map.deinit();
        self.attrib_map.deinit();
        self.macros.deinit();

        gl.deleteShader(self.vert_shader);
        gl.deleteShader(self.geom_shader);
        gl.deleteShader(self.frag_shader);
        gl.deleteProgram(self.prog);

        self.allocator.destroy(self);
    }
};
