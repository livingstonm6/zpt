const v = @import("vec3.zig");

pub const ray = struct { origin: v.point3, direction: v.vec3 };

pub fn at(r: *const ray, t: f64) v.point3 {
    return v.vec3Add(r.origin, v.vec3Multiply(r.direction, t));
}
