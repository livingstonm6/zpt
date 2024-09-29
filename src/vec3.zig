const std = @import("std");
const util = @import("util.zig");

pub const vec3 = struct {
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
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

pub fn cross(v1: *const vec3, v2: *const vec3) vec3 {
    return vec3{
        .x = v1.y * v2.z - v1.z * v2.y,
        .y = v1.z * v2.x - v1.x * v2.z,
        .z = v1.x * v2.y - v1.y * v2.x,
    };
}

pub fn vecMultiply(v1: *const vec3, v2: *const vec3) vec3 {
    return vec3{
        .x = v1.x * v2.x,
        .y = v1.y * v2.y,
        .z = v1.z * v2.z,
    };
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

pub fn nearZero(v: *const vec3) bool {
    const s = 1e-8;
    return @abs(v.x) < s and @abs(v.y) < s and @abs(v.z) < s;
}

pub fn reflect(v: *const vec3, n: *const vec3) vec3 {
    const term2 = multiply(n, 2 * dotProduct(v, n));
    return subtract(v, &term2);
}

pub fn refract(uv: *const vec3, n: *const vec3, etai_over_etat: f64) vec3 {
    var cos_theta = dotProduct(&multiply(uv, -1), n);
    if (cos_theta > 1.0) {
        cos_theta = 1.0;
    }
    const r_out_perp = multiply(&add(uv, &multiply(n, cos_theta)), etai_over_etat);
    const r_out_parallel = multiply(n, -std.math.sqrt(@abs(1.0 - lengthSquared(&r_out_perp))));
    return add(&r_out_perp, &r_out_parallel);
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

test "cross" {
    const v1 = vec3{ .x = 1, .y = 0, .z = 0 };
    const v2 = vec3{ .x = 0, .y = 1, .z = 0 };
    const v3 = vec3{ .x = 0, .y = 0, .z = 1 };
    const result = cross(&v1, &v2);

    try std.testing.expectEqual(result.x, v3.x);
    try std.testing.expectEqual(result.y, v3.y);
    try std.testing.expectEqual(result.z, v3.z);
}

test "cross 2" {
    const v1 = vec3{ .x = -1, .y = 0, .z = 1 };
    const v2 = vec3{ .x = 1, .y = 1, .z = 1 };
    const v3 = vec3{ .x = -1, .y = 2, .z = -1 };
    const result = cross(&v1, &v2);

    try std.testing.expectEqual(result.x, v3.x);
    try std.testing.expectEqual(result.y, v3.y);
    try std.testing.expectEqual(result.z, v3.z);
}
