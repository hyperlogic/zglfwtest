const std = @import("std");
const Io = std.Io;
const zglfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zglfwtest = @import("zglfwtest");
const math = @import("math/root.zig");
const FlyCam = @import("flycam.zig").FlyCam;

const vert_shader_source = @embedFile("shader/vert.glsl");
const frag_shader_source = @embedFile("shader/frag.glsl");

fn compile_shader(source: []const u8, shader_type: gl.Enum) !gl.Uint {
    const shader = gl.createShader(shader_type);
    if (shader == 0) {
        return error.CreateShaderFailed;
    }
    errdefer gl.deleteShader(shader);

    const src_ptr: [*c]const gl.Char = source.ptr;
    const src_len: gl.Int = @intCast(source.len);
    gl.shaderSource(shader, 1, &src_ptr, &src_len);
    gl.compileShader(shader);

    var compiled: gl.Int = gl.FALSE;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &compiled);

    if (compiled == 0) {
        var log_buf: [1024]u8 = undefined;
        var log_len: gl.Sizei = 0;
        gl.getShaderInfoLog(shader, log_buf.len, &log_len, &log_buf);
        std.log.err("shader compile failed:\n{s}", .{log_buf[0..@intCast(log_len)]});
        return error.ShaderCompileFailed;
    }
    return shader;
}

fn link_program(vert_shader: gl.Uint, frag_shader: gl.Uint) !gl.Uint {
    const program = gl.createProgram();
    if (program == 0) {
        return error.CreateProgramFailed;
    }
    errdefer gl.deleteProgram(program);

    gl.attachShader(program, vert_shader);
    gl.attachShader(program, frag_shader);
    gl.linkProgram(program);

    var linked: gl.Int = gl.FALSE;
    gl.getProgramiv(program, gl.LINK_STATUS, &linked);

    if (linked == 0) {
        var log_buf: [1024]u8 = undefined;
        var log_len: gl.Sizei = 0;
        gl.getProgramInfoLog(program, log_buf.len, &log_len, &log_buf);
        std.log.err("program link failed:\n{s}", .{log_buf[0..@intCast(log_len)]});
        return error.ProgramLinkFailed;
    }

    return program;
}

pub fn main(init: std.process.Init) !void {

    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try zglfwtest.printAnotherMessage(stdout_writer);

    try stdout_writer.flush(); // Don't forget to flush!

    _ = zglfw.setErrorCallback(onGlfwError);

    try zglfw.init();
    defer zglfw.terminate();

    const window = try zglfw.createWindow(600, 600, "zig-gamedev: minimal_glfw_gl", null, null);
    defer zglfw.destroyWindow(window);

    // The OpenGL context must be current on this thread, otherwise
    // swapBuffers() is a no-op and on Wayland the surface never gets a
    // buffer, so the compositor never shows the window.
    zglfw.makeContextCurrent(window);
    zglfw.swapInterval(1);

    try zopengl.loadCoreProfile(zglfw.getProcAddress, 4, 0);

    // setup your graphics context here
    const vert_shader: gl.Uint = try compile_shader(vert_shader_source, gl.VERTEX_SHADER);
    defer gl.deleteShader(vert_shader);
    const frag_shader: gl.Uint = try compile_shader(frag_shader_source, gl.FRAGMENT_SHADER);
    defer gl.deleteShader(frag_shader);
    const prog: gl.Uint = try link_program(vert_shader, frag_shader);
    defer gl.deleteProgram(prog);

    const positions = [_]math.Vec3f{
        math.Vec3f.init(0, 0, 0), math.Vec3f.init(1, 0, 0),
        math.Vec3f.init(0, 0, 0), math.Vec3f.init(0, 1, 0),
        math.Vec3f.init(0, 0, 0), math.Vec3f.init(0, 0, 1),
    };

    const colors = [_]math.Vec4f{
        math.Vec4f.init(1, 0, 0, 1), math.Vec4f.init(1, 0, 0, 1),
        math.Vec4f.init(0, 1, 0, 1), math.Vec4f.init(0, 1, 0, 1),
        math.Vec4f.init(0, 0, 1, 1), math.Vec4f.init(0, 0, 1, 1),
    };

    var flycam = FlyCam.init(
        math.Vec3f.init(1, 0, 0), // world_up
        math.Vec3f.init(0, 0, 10), // pos
        math.Quatf.identity, // rot
        10.0, // speed
        1.0, // rot_speed
    );

    var last_time = zglfw.getTime();
    while (!window.shouldClose()) {
        const now = zglfw.getTime();
        const dt: f32 = @min(@as(f32, @floatCast(now - last_time)), 0.1);
        last_time = now;

        zglfw.pollEvents();

        var left_stick = math.Vec2f.splat(0);
        var right_stick = math.Vec2f.splat(0);

        if (window.getKey(.w) == .press) {
            left_stick.y += 1;
        }
        if (window.getKey(.a) == .press) {
            left_stick.x -= 1;
        }
        if (window.getKey(.s) == .press) {
            left_stick.y -= 1;
        }
        if (window.getKey(.d) == .press) {
            left_stick.x += 1;
        }
        if (window.getKey(.left) == .press) {
            right_stick.x -= 1;
        }
        if (window.getKey(.right) == .press) {
            right_stick.x += 1;
        }
        if (window.getKey(.up) == .press) {
            right_stick.y += 1;
        }
        if (window.getKey(.down) == .press) {
            right_stick.y -= 1;
        }
        if (window.getKey(.escape) == .press) {
            window.setShouldClose(true);
        }

        flycam.process(left_stick, right_stick, 0.0, 0.0, dt);

        const fb_size = window.getFramebufferSize();
        gl.viewport(0, 0, fb_size[0], fb_size[1]);
        const width: f32 = @floatFromInt(fb_size[0]);
        const height: f32 = @floatFromInt(fb_size[1]);
        const aspect = width / height;
        const proj_mat = math.Mat4f.initPerspective(std.math.degreesToRadians(45), aspect, 0.01, 1000.0);

        const color = [_]f32{ 0.0, 0.0, 0.0, 1.0 };
        gl.clearBufferfv(gl.COLOR, 0, &color);

        const cam_mat = flycam.camera_mat;
        const view_mat = cam_mat.orthoInverse();
        const model_view_proj_mat = proj_mat.mul(view_mat);

        gl.useProgram(prog);
        gl.uniformMatrix4fv(0, 1, gl.FALSE, @ptrCast(&model_view_proj_mat));
        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, @ptrCast(&positions));
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 0, @ptrCast(&colors));
        gl.enableVertexAttribArray(1);
        gl.drawArrays(gl.LINES, 0, @intCast(positions.len));

        window.swapBuffers();
    }
    zglfw.pollEvents(); // flush Wayland queue before terminate
}

fn onGlfwError(code: zglfw.ErrorCode, desc: ?[*:0]const u8) callconv(.c) void {
    std.log.err("glfw error {d}: {s}", .{ code, desc orelse "" });
}

test {
    // Reference the math modules so their tests are analyzed and run.
    _ = .{ math.Vec3f, math.Vec3f, math.Vec4f, math.Quatf, math.Mat3f, math.Mat4f, math.Aabbf, math.Xformf };
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try command `zig build test --fuzz -Doptimize=ReleaseFast` to see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
