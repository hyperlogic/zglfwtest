const std = @import("std");
const gl = @import("zopengl").bindings;

pub fn checkError(msg: []const u8) void {
    const err_val = gl.getError();
    if (err_val == gl.NO_ERROR) {
        return;
    }
    const err_str = switch (err_val) {
        gl.INVALID_ENUM => "GL_INVALID_ENUM",
        gl.INVALID_VALUE => "GL_INVALID_VALUE",
        gl.INVALID_FRAMEBUFFER_OPERATION => "GL_INVALID_FRAMEBUFFER_OPERATION",
        gl.OUT_OF_MEMORY => "GL_OUT_OF_MEMORY",
        gl.STACK_UNDERFLOW => "GL_STACK_UNDERFLOW",
        gl.STACK_OVERFLOW => "GL_STACK_OVERFLOW",
        else => "UNKNOWN_ERROR",
    };
    std.log.warn("{s} glGetError {s} ({any})", .{ msg, err_str, err_val });
}

pub fn compile_shader(source: []const u8, shader_type: gl.Enum) !gl.Uint {
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
