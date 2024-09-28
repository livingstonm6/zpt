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
