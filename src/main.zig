const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const h = @import("hittable.zig");
const cam = @import("camera.zig");
const m = @import("material.zig");

pub fn main() !void {
    // Init hittable list
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(gpa.allocator());
    defer world.hittableList.deinit();

    // Define materials
    const mat_ground = m.Material{ .lambertian = m.Lambertian{
        .albedo = c.color{ .x = 0.8, .y = 0.8, .z = 0.0 },
    } };
    const mat_center = m.Material{ .lambertian = m.Lambertian{
        .albedo = c.color{ .x = 0.1, .y = 0.2, .z = 0.5 },
    } };
    const mat_left = m.Material{ .metal = m.Metal{
        .albedo = c.color{ .x = 0.8, .y = 0.8, .z = 0.8 },
    } };
    const mat_right = m.Material{ .metal = m.Metal{
        .albedo = c.color{ .x = 0.8, .y = 0.6, .z = 0.2 },
    } };

    // Set up scene
    try world.hittableList.push(h.Hittable{
        .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = -100.5, .z = -1 }, .radius = 100.0, .mat = mat_ground },
    });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = 0.0, .z = -1.2 }, .radius = 0.5, .mat = mat_center } });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = -1.0, .y = 0.0, .z = -1.0 }, .radius = 0.5, .mat = mat_left } });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 1.0, .y = 0.0, .z = -1.0 }, .radius = 0.5, .mat = mat_right } });

    // Set up camera and render
    var camera = cam.Camera{};
    camera.image_width = 1920;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    try camera.render(&world);
}
