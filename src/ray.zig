const v = @import("vec3.zig");

pub const ray = struct { origin: v.point3, direction: v.vec3 };

pub fn at(r: *const ray, t: f64) v.point3 {
    return v.add(&r.origin, &v.multiply(&r.direction, t));
}
