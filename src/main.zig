const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const interval = @import("interval.zig");
const cam = @import("camera.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(gpa.allocator());
    defer world.hittableList.deinit();

    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = 0, .z = -1 }, .radius = 0.5 } });
    try world.hittableList.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = -100.5, .z = -1 }, .radius = 100 } });

    var camera = cam.Camera{};
    camera.samples_per_pixel = 100;

    try camera.render(&world);
}
