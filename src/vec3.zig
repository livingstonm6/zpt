const std = @import("std");
const util = @import("util.zig");

pub const vec3 = struct {
    x: f64,
    y: f64,
    z: f64,
};

pub const point3 = vec3;

pub fn add(v1: *const vec3, v2: *const vec3) vec3 {
    return vec3{ .x = v1.x + v2.x, .y = v1.y + v2.y, .z = v1.z + v2.z };
}

pub fn subtract(v1: *const vec3, v2: *const vec3) vec3 {
    return vec3{ .x = v1.x - v2.x, .y = v1.y - v2.y, .z = v1.z - v2.z };
}

pub fn dotProduct(v1: *const vec3, v2: *const vec3) f64 {
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z);
}

pub fn multiply(v: *const vec3, c: f64) vec3 {
    return vec3{ .x = v.x * c, .y = v.y * c, .z = v.z * c };
}

pub fn divide(v: *const vec3, c: f64) vec3 {
    return vec3{ .x = v.x / c, .y = v.y / c, .z = v.z / c };
}

pub fn lengthSquared(v: *const vec3) f64 {
    return (v.x * v.x) + (v.y * v.y) + (v.z * v.z);
}

pub fn length(v: *const vec3) f64 {
    return std.math.sqrt(lengthSquared(v));
}

pub fn unit(v: *const vec3) vec3 {
    return divide(v, length(v));
}

pub fn random() !vec3 {
    return vec3{
        .x = try util.randomF64(),
        .y = try util.randomF64(),
        .z = try util.randomF64(),
    };
}

pub fn randomRange(min: f64, max: f64) !vec3 {
    return vec3{
        .x = try util.randomF64Range(min, max),
        .y = try util.randomF64Range(min, max),
        .z = try util.randomF64Range(min, max),
    };
}

pub fn randomUnit() !vec3 {
    while (true) {
        const p = try randomRange(-1, 1);
        const lenSq = lengthSquared(&p);
        if (1e-160 < lenSq and lenSq <= 1) {
            return divide(&p, std.math.sqrt(lenSq));
        }
    }
}

pub fn randomOnHemisphere(normal: *const vec3) !vec3 {
    const on_unit_sphere = try randomUnit();
    if (dotProduct(&on_unit_sphere, normal) > 0.0) {
        return on_unit_sphere;
    }
    return multiply(&on_unit_sphere, -1);
}

test "add" {
    const v1 = vec3{ .x = 1, .y = 1, .z = 1 };
    const v2 = vec3{ .x = 1, .y = 2, .z = 3 };
    const v3 = vec3{ .x = 2, .y = 3, .z = 4 };
    const result = add(&v1, &v2);

    try std.testing.expectEqual(result.x, v3.x);
    try std.testing.expectEqual(result.y, v3.y);
    try std.testing.expectEqual(result.z, v3.z);
}

test "subtract" {
    const v1 = vec3{ .x = 1, .y = 1, .z = 1 };
    const v2 = vec3{ .x = 1, .y = 2, .z = 3 };
    const v3 = vec3{ .x = 0, .y = 1, .z = 2 };
    const result = subtract(&v2, &v1);

    try std.testing.expectEqual(result.x, v3.x);
    try std.testing.expectEqual(result.y, v3.y);
    try std.testing.expectEqual(result.z, v3.z);
}
