const std = @import("std");

pub const vec3 = struct {
    x: f64,
    y: f64,
    z: f64,
};

pub fn vec3Add(v1: *vec3, v2: *vec3) vec3 {
    return vec3{ .x = v1.x + v2.x, .y = v1.y + v2.y, .z = v2.z + v2.z };
}

pub fn vec3DotProduct(v1: *vec3, v2: *vec3) f64 {
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z);
}

pub fn vec3Multiply(v: *vec3, c: f64) vec3 {
    return vec3{ .x = v.x * c, .y = v.y * c, .z = v.z * c };
}

pub fn vec3Divide(v: *vec3, c: f64) vec3 {
    return vec3{ .x = v.x / c, .y = v.y / c, .z = v.z / c };
}

pub fn vec3LengthSquared(v: *vec3) f64 {
    return (v.x * v.x) + (v.y * v.y) + (v.z + v.z);
}

pub fn vec3Length(v: *vec3) f64 {
    return std.math.sqrt(vec3LengthSquared(v));
}

pub fn vec3Unit(v: *vec3) vec3 {
    return vec3Divide(v, vec3Length(v));
}
