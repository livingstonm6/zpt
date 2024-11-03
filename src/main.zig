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
const q = @import("quad.zig");
const vol = @import("volume.zig");
const inst = @import("instance.zig");

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

    camera.background = c.color{ .x = 0.7, .y = 0.8, .z = 1.0 };

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

    camera.background = c.color{ .x = 0.7, .y = 0.8, .z = 1.0 };

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
    camera.background = c.color{ .x = 0.7, .y = 0.8, .z = 1.0 };

    try camera.render(&h.Hittable{ .sphere = globe });
}

pub fn perlinSpheres() !void {
    var world = h.Hittable{ .hittableList = h.HittableList{} };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    var pertext = t.Texture{ .noiseTexture = t.NoiseTexture{ .scale = 4 } };
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
    camera.background = c.color{ .x = 0.7, .y = 0.8, .z = 1.0 };

    try camera.render(&world);
}

fn quads() !void {
    // Mats
    var red_lamb = m.Lambertian{};
    red_lamb.initAlbedo(c.color{ .x = 1.0, .y = 0.2, .z = 0.2 });
    const left_red = m.Material{ .lambertian = red_lamb };

    var green_lamb = m.Lambertian{};
    green_lamb.initAlbedo(c.color{ .x = 0.2, .y = 1.0, .z = 0.2 });
    const back_green = m.Material{ .lambertian = green_lamb };

    var blue_lamb = m.Lambertian{};
    blue_lamb.initAlbedo(c.color{ .x = 0.2, .y = 0.2, .z = 1.0 });
    const right_blue = m.Material{ .lambertian = blue_lamb };

    var orange_lamb = m.Lambertian{};
    orange_lamb.initAlbedo(c.color{ .x = 1.0, .y = 0.5, .z = 0.0 });
    const upper_orange = m.Material{ .lambertian = orange_lamb };

    var teal_lamb = m.Lambertian{};
    teal_lamb.initAlbedo(c.color{ .x = 0.2, .y = 0.8, .z = 0.8 });
    const lower_teal = m.Material{ .lambertian = teal_lamb };

    // HittableList

    var world = h.Hittable{ .hittableList = h.HittableList{} };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    const left = q.Quad{
        .q = v.point3{ .x = -3, .y = -2, .z = 5 },
        .u = v.vec3{ .x = 0, .y = 0, .z = -4 },
        .v = v.vec3{ .x = 0, .y = 4, .z = 0 },
        .mat = left_red,
    };

    const back = q.Quad{ .q = v.point3{ .x = -2, .y = -2, .z = 0 }, .u = v.vec3{ .x = 4, .y = 0, .z = 0 }, .v = v.vec3{ .x = 0, .y = 4, .z = 0 }, .mat = back_green };

    const right = q.Quad{ .q = v.point3{ .x = 3, .y = -2, .z = 1 }, .u = v.vec3{ .x = 0, .y = 0, .z = 4 }, .v = v.vec3{ .x = 0, .y = 4, .z = 0 }, .mat = right_blue };

    const upper = q.Quad{ .q = v.point3{ .x = -2, .y = 3, .z = 1 }, .u = v.vec3{ .x = 4, .y = 0, .z = 0 }, .v = v.vec3{ .x = 0, .y = 0, .z = 4 }, .mat = upper_orange };

    const lower = q.Quad{ .q = v.point3{ .x = -2, .y = -3, .z = 5 }, .u = v.vec3{ .x = 4, .y = 0, .z = 0 }, .v = v.vec3{ .x = 0, .y = 0, .z = -4 }, .mat = lower_teal };

    try world.hittableList.pushQuad(left);
    try world.hittableList.pushQuad(back);
    try world.hittableList.pushQuad(right);
    try world.hittableList.pushQuad(upper);
    try world.hittableList.pushQuad(lower);

    var camera = cam.Camera{};

    camera.aspect_ratio = 1.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;

    camera.vertical_fov = 80;
    camera.look_from = v.point3{ .x = 0, .y = 0, .z = 9 };
    camera.look_at = v.point3{ .x = 0, .y = 0, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;
    camera.background = c.color{ .x = 0.7, .y = 0.8, .z = 1.0 };

    try camera.render(&world);
}

fn simpleLight() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    var pertext = t.Texture{ .noiseTexture = t.NoiseTexture{ .scale = 4 } };
    try pertext.noiseTexture.init(allocator);

    const mat = m.Material{ .lambertian = m.Lambertian{ .texture = pertext } };

    const sphere1 = h.Sphere{
        .center = r.ray{ .origin = v.point3{ .x = 0, .y = -1000, .z = 0 } },
        .radius = 1000,
        .mat = mat,
    };

    const sphere2 = h.Sphere{
        .center = r.ray{ .origin = v.point3{ .x = 0, .y = 2, .z = 0 } },
        .radius = 2,
        .mat = mat,
    };

    try world.hittableList.pushSphere(sphere1);
    try world.hittableList.pushSphere(sphere2);

    var diff_light = m.Material{ .diffuseLight = m.DiffuseLight{} };
    diff_light.diffuseLight.initColor(c.color{ .x = 4, .y = 4, .z = 4 });
    const quad = q.Quad{
        .q = v.point3{ .x = 3, .y = 1, .z = -2 },
        .u = v.vec3{ .x = 2, .y = 0, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 2, .z = 0 },
        .mat = diff_light,
    };
    try world.hittableList.pushQuad(quad);

    const sphereLight = h.Sphere{
        .center = r.ray{ .origin = v.point3{ .x = 0, .y = 7, .z = 0 } },
        .radius = 2,
        .mat = diff_light,
    };
    try world.hittableList.pushSphere(sphereLight);

    var camera = cam.Camera{};

    camera.aspect_ratio = 16.0 / 9.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 100;
    camera.max_recursion_depth = 50;
    camera.background = c.color{ .x = 0, .y = 0, .z = 0 };

    camera.vertical_fov = 20;
    camera.look_from = v.point3{ .x = 26, .y = 3, .z = 6 };
    camera.look_at = v.point3{ .x = 0, .y = 2, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    try camera.render(&world);
}

fn cornellBox() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    var red = m.Material{ .lambertian = m.Lambertian{} };
    red.lambertian.initAlbedo(c.color{ .x = 0.65, .y = 0.05, .z = 0.05 });

    var white = m.Material{ .lambertian = m.Lambertian{} };
    white.lambertian.initAlbedo(c.color{ .x = 0.73, .y = 0.73, .z = 0.73 });

    var green = m.Material{ .lambertian = m.Lambertian{} };
    green.lambertian.initAlbedo(c.color{ .x = 0.12, .y = 0.45, .z = 0.15 });

    var light = m.Material{ .diffuseLight = m.DiffuseLight{} };
    light.diffuseLight.initColor(c.color{ .x = 15, .y = 15, .z = 15 });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 555, .y = 0, .z = 0 },
        .u = v.vec3{ .x = 0, .y = 555, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 0, .z = 555 },
        .mat = green,
    });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 0, .y = 0, .z = 0 },
        .u = v.vec3{ .x = 0, .y = 555, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 0, .z = 555 },
        .mat = red,
    });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 343, .y = 555, .z = 332 },
        .u = v.vec3{ .x = -130, .y = 0, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 0, .z = -105 },
        .mat = light,
    });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 0, .y = 0, .z = 0 },
        .u = v.vec3{ .x = 555, .y = 0, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 0, .z = 555 },
        .mat = white,
    });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 555, .y = 555, .z = 555 },
        .u = v.vec3{ .x = -555, .y = 0, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 0, .z = -555 },
        .mat = white,
    });

    try world.hittableList.pushQuad(q.Quad{
        .q = v.point3{ .x = 0, .y = 0, .z = 555 },
        .u = v.vec3{ .x = 555, .y = 0, .z = 0 },
        .v = v.vec3{ .x = 0, .y = 555, .z = 0 },
        .mat = white,
    });

    var box1 = h.Hittable{ .hittableList = try q.box(&v.point3{ .x = 0, .y = 0, .z = 0 }, &v.point3{ .x = 165, .y = 330, .z = 165 }, white, allocator) };
    defer box1.hittableList.deinit();

    var rotated_box1 = inst.RotateY{ .object = &box1 };
    rotated_box1.init(15);

    var translated_box1 = inst.Translate{ .object = &h.Hittable{ .rotateY = rotated_box1 }, .offset = v.vec3{ .x = 265, .y = 0, .z = 295 } };
    translated_box1.initBoundingBox();

    var box2 = h.Hittable{ .hittableList = try q.box(&v.point3{ .x = 0, .y = 0, .z = 0 }, &v.point3{ .x = 165, .y = 165, .z = 165 }, white, allocator) };
    defer box2.hittableList.deinit();

    var rotated_box2 = inst.RotateY{ .object = &box2 };
    rotated_box2.init(-18);

    var translated_box2 = inst.Translate{ .object = &h.Hittable{ .rotateY = rotated_box2 }, .offset = v.vec3{ .x = 130, .y = 0, .z = 65 } };
    translated_box2.initBoundingBox();

    try world.hittableList.pushTranslate(translated_box1);
    try world.hittableList.pushTranslate(translated_box2);

    var camera = cam.Camera{};

    camera.aspect_ratio = 1.0;
    camera.image_width = 400;
    camera.samples_per_pixel = 200;
    camera.max_recursion_depth = 50;
    camera.background = c.color{ .x = 0, .y = 0, .z = 0 };

    camera.vertical_fov = 40;
    camera.look_from = v.point3{ .x = 278, .y = 278, .z = -800 };
    camera.look_at = v.point3{ .x = 278, .y = 278, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    // build BVH

    var bvh = h.Hittable{ .bvh = bv.BVHNode{} };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    try bvh.bvh.initTree(&world.hittableList, arena.allocator());
    try camera.render(&bvh);
}

pub fn finalScene(image_width: usize, samples_per_pixel: usize, max_depth: usize) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var boxes1 = h.Hittable{ .hittableList = h.HittableList{} };
    boxes1.hittableList.init(allocator);
    defer boxes1.hittableList.deinit();

    var ground = m.Material{ .lambertian = m.Lambertian{} };
    ground.lambertian.initAlbedo(c.color{ .x = 0.48, .y = 0.83, .z = 0.53 });

    const boxes_per_side = 20;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    for (0..boxes_per_side) |i| {
        for (0..boxes_per_side) |j| {
            const f_i: f64 = @floatFromInt(i);
            const f_j: f64 = @floatFromInt(j);
            const w: f64 = 100.0;

            const point1 = v.point3{
                .x = -1000.0 + f_i * w,
                .y = 0.0,
                .z = -1000.0 + f_j * w,
            };

            const point2 = v.point3{
                .x = point1.x + w,
                .y = try util.randomF64Range(1, 101),
                .z = point1.z + w,
            };

            const box = try q.box(&point1, &point2, ground, arena.allocator());
            // defer box.deinit();

            try boxes1.hittableList.pushHittableList(&box);
        }
    }

    var world = h.Hittable{ .hittableList = h.HittableList{} };
    world.hittableList.init(allocator);
    defer world.hittableList.deinit();

    var bvh1 = h.Hittable{ .bvh = bv.BVHNode{} };
    try bvh1.bvh.initTree(&boxes1.hittableList, arena.allocator());

    try world.hittableList.pushHittable(bvh1);

    var light = m.Material{ .diffuseLight = m.DiffuseLight{} };
    light.diffuseLight.initColor(c.color{ .x = 7, .y = 7, .z = 7 });

    const light_quad = q.Quad{
        .q = v.point3{ .x = 123, .y = 554, .z = 147 },
        .u = v.point3{ .x = 300, .y = 0, .z = 0 },
        .v = v.point3{ .x = 0, .y = 0, .z = 265 },
        .mat = light,
    };
    try world.hittableList.pushQuad(light_quad);

    const center1 = v.point3{ .x = 400, .y = 400, .z = 200 };
    const center2 = v.point3{ .x = 430, .y = 400, .z = 200 };
    var sphere_mat = m.Material{ .lambertian = m.Lambertian{} };
    sphere_mat.lambertian.initAlbedo(c.color{ .x = 0.7, .y = 0.3, .z = 0.1 });
    try world.hittableList.pushSphere(h.Sphere{
        .center = r.ray{
            .origin = center1,
            .direction = v.subtract(&center2, &center1),
        },
        .radius = 50,
        .mat = sphere_mat,
    });

    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{
        .origin = v.vec3{ .x = 260, .y = 150, .z = 45 },
    }, .radius = 50, .mat = m.Material{ .dielectric = m.Dielectric{ .refraction_index = 1.5 } } });

    try world.hittableList.pushSphere(h.Sphere{
        .center = r.ray{
            .origin = v.vec3{ .x = 0, .y = 150, .z = 145 },
        },
        .radius = 50,
        .mat = m.Material{ .metal = m.Metal{ .albedo = c.color{ .x = 0.8, .y = 0.8, .z = 0.9 }, .fuzz = 1.0 } },
    });

    var boundary = h.Sphere{
        .center = r.ray{
            .origin = v.point3{ .x = 360, .y = 150, .z = 145 },
        },
        .radius = 70,
        .mat = m.Material{ .dielectric = m.Dielectric{ .refraction_index = 1.5 } },
    };
    boundary.initBoundingBox();
    try world.hittableList.pushSphere(boundary);

    var cm1 = vol.ConstantMedium{ .boundary = &h.Hittable{ .sphere = boundary } };
    cm1.initAlbedo(0.2, &c.color{ .x = 0.2, .y = 0.4, .z = 0.9 });
    try world.hittableList.pushHittable(h.Hittable{ .constantMedium = cm1 });

    var boundary2 = h.Sphere{
        .center = r.ray{},
        .radius = 5000,
        .mat = m.Material{ .dielectric = m.Dielectric{ .refraction_index = 1.5 } },
    };
    boundary2.initBoundingBox();
    var cm2 = vol.ConstantMedium{ .boundary = &h.Hittable{ .sphere = boundary2 } };
    cm2.initAlbedo(0.0001, &c.color{ .x = 1, .y = 1, .z = 1 });
    try world.hittableList.pushHittable(h.Hittable{ .constantMedium = cm2 });

    var emat = m.Material{ .lambertian = m.Lambertian{ .texture = t.Texture{ .imageTexture = t.ImageTexture{ .fileName = "earthmap.jpg" } } } };
    try emat.lambertian.texture.imageTexture.init(allocator);
    defer emat.lambertian.texture.imageTexture.deinit();
    try world.hittableList.pushSphere(h.Sphere{ .center = r.ray{
        .origin = v.point3{ .x = 400, .y = 200, .z = 400 },
    }, .radius = 100, .mat = emat });

    var boxes2 = h.Hittable{ .hittableList = h.HittableList{} };
    boxes2.hittableList.init(allocator);
    defer boxes2.hittableList.deinit();

    var white = m.Material{ .lambertian = m.Lambertian{} };
    white.lambertian.initAlbedo(c.color{ .x = 0.73, .y = 0.73, .z = 0.73 });
    const ns = 1000;
    for (0..ns) |j| {
        _ = j;
        try boxes2.hittableList.pushSphere(h.Sphere{
            .center = r.ray{ .origin = try v.randomRange(0, 165) },
            .radius = 10,
            .mat = white,
        });
    }

    var bvh2 = h.Hittable{ .bvh = bv.BVHNode{} };
    try bvh2.bvh.initTree(&boxes2.hittableList, arena.allocator());

    var rotate = inst.RotateY{
        .object = &bvh2,
    };
    rotate.init(15);

    const translate = inst.Translate{ .object = &h.Hittable{ .rotateY = rotate }, .offset = v.vec3{ .x = -100, .y = 270, .z = 395 } };
    try world.hittableList.pushTranslate(translate);

    var camera = cam.Camera{};
    camera.aspect_ratio = 1.0;
    camera.image_width = image_width;
    camera.samples_per_pixel = samples_per_pixel;
    camera.max_recursion_depth = max_depth;
    camera.background = c.color{};

    camera.vertical_fov = 40;
    camera.look_from = v.point3{ .x = 478, .y = 278, .z = -600 };
    camera.look_at = v.point3{ .x = 278, .y = 278, .z = 0 };
    camera.v_up = v.vec3{ .x = 0, .y = 1, .z = 0 };

    camera.dof_angle = 0;

    try camera.render(&world);
}

pub fn main() !void {
    switch (8) {
        1 => try bouncingSpheres(),
        2 => try checkeredSpheres(),
        3 => try earth(),
        4 => try perlinSpheres(),
        5 => try quads(),
        6 => try simpleLight(),
        7 => try cornellBox(),
        8 => try finalScene(800, 10000, 40),
        9 => try finalScene(400, 250, 4),

        else => {},
    }
}
