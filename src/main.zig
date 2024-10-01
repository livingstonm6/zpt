const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const h = @import("hittable.zig");
const cam = @import("camera.zig");
const m = @import("material.zig");
const util = @import("util.zig");
const r = @import("ray.zig");

pub fn main() !void {
    // Init hittable list
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(gpa.allocator());
    defer world.hittableList.deinit();

    // Define materials
    const mat_ground = m.Material{ .lambertian = m.Lambertian{
        .albedo = c.color{ .x = 0.5, .y = 0.5, .z = 0.5 },
    } };
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = -1000, .z = 0 } }, .radius = 1000, .mat = mat_ground } });
    var a: i8 = -11;
    while (a < 11) : (a += 1) {
        var b: i8 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = try util.randomF64();
            const center = v.point3{
                .x = @as(f64, @floatFromInt(a)) + (0.9 * try util.randomF64()),
                .y = 0.2,
                .z = @as(f64, @floatFromInt(b)) + (0.9 * try util.randomF64()),
            };
            if (v.length(&v.subtract(&center, &v.point3{ .x = 4, .y = 0.2, .z = 0 })) > 0.9) {
                var material: m.Material = undefined;

                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = v.vecMultiply(&try v.random(), &try v.random());
                    material = m.Material{ .lambertian = m.Lambertian{
                        .albedo = albedo,
                    } };
                    const center2 = v.add(&center, &v.vec3{ .x = 0, .y = try util.randomF64Range(0, 0.5), .z = 0 });

                    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = center, .direction = v.subtract(&center2, &center) }, .radius = 0.2, .mat = material } });
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = try v.randomRange(0.5, 1);
                    const fuzz = try util.randomF64Range(0, 0.5);
                    material = m.Material{ .metal = m.Metal{ .albedo = albedo, .fuzz = fuzz } };
                    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = center }, .radius = 0.2, .mat = material } });
                } else {
                    // glass
                    material = m.Material{ .dielectric = m.Dielectric{
                        .refraction_index = 1.5,
                    } };
                    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = center }, .radius = 0.2, .mat = material } });
                }
            }
        }
    }

    const mat1 = m.Material{ .dielectric = m.Dielectric{
        .refraction_index = 1.50,
    } };

    const mat2 = m.Material{ .lambertian = m.Lambertian{
        .albedo = c.color{ .x = 0.4, .y = 0.2, .z = 0.1 },
    } };

    const mat3 = m.Material{ .metal = m.Metal{
        .albedo = c.color{ .x = 0.7, .y = 0.6, .z = 0.5 },
        .fuzz = 0.0,
    } };

    // Set up scene
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat1 } });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = -4, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat2 } });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 4, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat3 } });

    // Set up camera and render
    var camera = cam.Camera{};
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    camera.vertical_fov = 20;
    camera.look_from = v.point3{ .x = 13, .y = 2, .z = 3 };
    camera.look_at = v.point3{ .x = 0, .y = 0, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0.6;
    camera.focus_dist = 10.0;

    try camera.render(&world);
}
