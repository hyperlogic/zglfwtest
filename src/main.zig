const std = @import("std");
const Io = std.Io;
const zglfw = @import("zglfw");
const zopengl = @import("zopengl");
const zglfwtest = @import("zglfwtest");
const math = @import("math/root.zig");

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
    const gl = zopengl.bindings;

    // test code
    const a = math.Vec3f.init(1, 2, 3);
    const b = math.Vec3f.init(4, 5, 6);
    const a_plus_b = a.add(b);
    std.debug.print("a + b = {f}\n", .{a_plus_b});

    const m = math.Mat4f.initTransRotUniformScale(a, math.Quatf.initAxisAngle(math.Vec3f.y_axis, std.math.radiansToDegrees(45)), 1);
    std.debug.print("m = {f}\n", .{m});

    while (!window.shouldClose()) {
        zglfw.pollEvents();

        // render your things here
        const color = [_]f32{ 1.0, 0.0, 0.0, 1.0 };
        gl.clearBufferfv(gl.COLOR, 0, &color);

        window.swapBuffers();
    }
    zglfw.pollEvents(); // flush Wayland queue before terminate
}

fn onGlfwError(code: zglfw.ErrorCode, desc: ?[*:0]const u8) callconv(.c) void {
    std.log.err("glfw error {d}: {s}", .{ code, desc orelse "" });
}

test {
    // Reference the math modules so their tests are analyzed and run.
    _ = .{ math.Vec3f, math.Vec3f, math.Vec4f, math.Quatf, math.Mat3f, math.Mat4f };
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
