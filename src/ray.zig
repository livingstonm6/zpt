const v = @import("vec3.zig");

pub const ray = struct {
    origin: v.point3 = v.point3{
        .x = 0,
        .y = 0,
        .z = 0,
    },
    direction: v.vec3 = v.vec3{ .x = 0, .y = 0, .z = 0 },
};

pub fn at(r: *const ray, t: f64) v.point3 {
    return v.add(&r.origin, &v.multiply(&r.direction, t));
}
