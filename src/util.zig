const std = @import("std");
const v = @import("vec3.zig");

pub fn randomF64() !f64 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();

    return rand.float(f64);
}

pub fn randomF64Range(min: f64, max: f64) !f64 {
    return min + ((max - min) * try randomF64());
}

pub fn randomU8Range(min: u8, max: u8) !u8 {
    const f_min = @as(f64, @floatFromInt(min));
    const f_max = @as(f64, @floatFromInt(max));
    const result = std.math.floor(try randomF64Range(f_min, f_max));
    return @as(u8, @intFromFloat(result));
}

pub fn randomUsizeRange(min: usize, max: usize) !usize {
    const f_min = @as(f64, @floatFromInt(min));
    const f_max = @as(f64, @floatFromInt(max));
    const result = std.math.floor(try randomF64Range(f_min, f_max));
    return @as(usize, @intFromFloat(result));
}
