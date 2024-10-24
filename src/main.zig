const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const h = @import("hittable.zig");
const cam = @import("camera.zig");
const m = @import("material.zig");
const util = @import("util.zig");
const r = @import("ray.zig");
const bv = @import("bvh.zig");
const t = @import("texture.zig");
const image = @import("image.zig");

pub fn bouncingSpheres() !void {
    // Init hittable list
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(gpa.allocator());
    defer world.hittableList.deinit();

    var checker = t.Texture{ .checkerTexture = t.CheckerTexture{} };

    const tex1 = try gpa.allocator().create(t.Texture);
    tex1.* = t.Texture{ .solidColor = t.SolidColor{ .albedo = c.color{ .x = 0.2, .y = 0.3, .z = 0.1 } } };
    defer gpa.allocator().destroy(tex1);

    const tex2 = try gpa.allocator().create(t.Texture);
    tex2.* = t.Texture{ .solidColor = t.SolidColor{ .albedo = c.color{ .x = 0.9, .y = 0.9, .z = 0.9 } } };
    defer gpa.allocator().destroy(tex2);

    checker.checkerTexture.init(0.32, tex1, tex2);

    var mat_ground = m.Material{ .lambertian = m.Lambertian{} };

    mat_ground.lambertian.initTexture(checker);

    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = -1000, .z = 0 } }, .radius = 1000, .mat = mat_ground });
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
                    var lamb = m.Lambertian{};
                    lamb.initAlbedo(albedo);

                    material = m.Material{ .lambertian = lamb };
                    const center2 = v.add(&center, &v.vec3{ .x = 0, .y = try util.randomF64Range(0, 0.5), .z = 0 });

                    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = center, .direction = v.subtract(&center2, &center) }, .radius = 0.2, .mat = material });
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = try v.randomRange(0.5, 1);
                    const fuzz = try util.randomF64Range(0, 0.5);
                    material = m.Material{ .metal = m.Metal{ .albedo = albedo, .fuzz = fuzz } };
                    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = center }, .radius = 0.2, .mat = material });
                } else {
                    // glass
                    material = m.Material{ .dielectric = m.Dielectric{
                        .refraction_index = 1.5,
                    } };
                    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = center }, .radius = 0.2, .mat = material });
                }
            }
        }
    }

    const mat1 = m.Material{ .dielectric = m.Dielectric{
        .refraction_index = 1.50,
    } };
    var lamb2 = m.Lambertian{};
    lamb2.initAlbedo(c.color{ .x = 0.4, .y = 0.2, .z = 0.1 });
    const mat2 = m.Material{ .lambertian = lamb2 };

    const mat3 = m.Material{ .metal = m.Metal{
        .albedo = c.color{ .x = 0.7, .y = 0.6, .z = 0.5 },
        .fuzz = 0.0,
    } };

    // Set up scene
    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat1 });
    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = -4, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat2 });
    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 4, .y = 1, .z = 0 } }, .radius = 1.0, .mat = mat3 });

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

    // build BVH

    var bvh = h.Hittable{ .bvh = bv.BVHNode{} };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    try bvh.bvh.initTree(&world.hittableList, arena.allocator());
    try camera.render(&bvh);
}

pub fn checkeredSpheres() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(gpa.allocator());
    defer world.hittableList.deinit();

    const evenTex = t.Texture{ .solidColor = t.SolidColor{ .albedo = c.color{ .x = 0.2, .y = 0.3, .z = 0.1 } } };
    const oddTex = t.Texture{ .solidColor = t.SolidColor{ .albedo = c.color{ .x = 0.9, .y = 0.9, .z = 0.9 } } };

    var tex = t.Texture{ .checkerTexture = t.CheckerTexture{} };
    tex.checkerTexture.init(0.32, &evenTex, &oddTex);

    var lamb = m.Lambertian{};
    lamb.initTexture(tex);
    const mat = m.Material{ .lambertian = lamb };
    const sphere1 = h.Sphere{ .center = r.ray{ .origin = v.vec3{ .x = 0, .y = -10, .z = 0 }, .direction = v.vec3{ .x = 0, .y = 0, .z = 0 } }, .radius = 10, .mat = mat };
    const sphere2 = h.Sphere{ .center = r.ray{ .origin = v.vec3{ .x = 0, .y = 10, .z = 0 }, .direction = v.vec3{ .x = 0, .y = 0, .z = 0 } }, .radius = 10, .mat = mat };

    try world.hittableList.pushSphere(sphere1);
    try world.hittableList.pushSphere(sphere2);

    var camera = cam.Camera{};

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    camera.vertical_fov = 20;
    camera.look_from = v.point3{ .x = 13, .y = 2, .z = 3 };
    camera.look_at = v.point3{ .x = 0, .y = 0, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    try camera.render(&world);
}

fn earth() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var earth_texture = t.ImageTexture{ .fileName = "earthmap.jpg" };
    try earth_texture.init(gpa.allocator());
    defer earth_texture.deinit();

    var lamb = m.Lambertian{};
    lamb.initTexture(t.Texture{ .imageTexture = earth_texture });

    const earth_surface = m.Material{ .lambertian = lamb };

    var globe = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = 0, .z = 0 }, .direction = v.vec3{ .x = 0, .y = 0, .z = 0 }, .time = 0 }, .radius = 2, .mat = earth_surface };
    globe.initBoundingBox();

    var camera = cam.Camera{};

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    camera.vertical_fov = 20;
    camera.look_from = v.point3{ .x = 0, .y = 0, .z = 12 };
    camera.look_at = v.point3{ .x = 0, .y = 0, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    try camera.render(&h.Hittable{ .sphere = globe });
}

pub fn perlinSpheres() !void {
    var world = h.Hittable{ .hittableList = h.HittableList{} };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    var pertext = t.Texture{ .noiseTexture = t.NoiseTexture{} };
    try pertext.noiseTexture.init(allocator);
    defer pertext.noiseTexture.deinit();

    const mat = m.Material{ .lambertian = m.Lambertian{ .texture = pertext } };

    const sphere1 = h.Sphere{ .center = r.ray{
        .origin = v.point3{ .x = 0, .y = -1000, .z = 0 },
    }, .radius = 1000, .mat = mat };
    const sphere2 = h.Sphere{ .center = r.ray{ .origin = v.point3{ .x = 0, .y = 2, .z = 0 } }, .radius = 2, .mat = mat };

    try world.hittableList.pushSphere(sphere1);
    try world.hittableList.pushSphere(sphere2);

    var camera = cam.Camera{};

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    camera.vertical_fov = 20;
    camera.look_from = v.point3{ .x = 13, .y = 2, .z = 3 };
    camera.look_at = v.point3{ .x = 0, .y = 0, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    try camera.render(&world);
}

pub fn main() !void {
    switch (4) {
        1 => try bouncingSpheres(),
        2 => try checkeredSpheres(),
        3 => try earth(),
        4 => try perlinSpheres(),
        else => {},
    }
}
