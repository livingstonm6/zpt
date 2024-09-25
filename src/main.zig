const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const interval = @import("interval.zig");

fn rayColor(ray: *const r.ray, world: *const h.HittableList) c.color {
    var record = h.HitRecord{
        .point = undefined,
        .normal = undefined,
        .t = undefined,
        .front_face = undefined,
    };
    if (world.hit(ray, interval.Interval{ .min = 0, .max = std.math.inf(f64) }, &record)) {
        return v.multiply(&v.add(&record.normal, &v.vec3{ .x = 1, .y = 1, .z = 1 }), 0.5);
    }

    // lerp
    const unit_direction = v.unit(&ray.direction);
    const a = 0.5 * (unit_direction.y + 1.0);

    const term1 = v.multiply(&v.vec3{ .x = 1.0, .y = 1.0, .z = 1.0 }, (1.0 - a));
    const term2 = v.multiply(&v.vec3{ .x = 0.5, .y = 0.7, .z = 1.0 }, a);
    return v.add(&term1, &term2);
}

pub fn main() !void {
    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u16 = 400;

    // Calculate image height (min 1)
    var image_height: u16 = image_width / aspect_ratio;
    if (image_height < 1) image_height = 1;

    // World
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = h.HittableList{};
    world.init(gpa.allocator());
    defer world.deinit();

    try world.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = 0, .z = -1 }, .radius = 0.5 } });
    try world.push(h.Hittable{ .sphere = h.Sphere{ .center = v.point3{ .x = 0, .y = -100.5, .z = -1 }, .radius = 100 } });

    // Camera
    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const width_over_height: f64 = @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const viewport_width: f64 = viewport_height * width_over_height;
    const camera_center = v.point3{ .x = 0, .y = 0, .z = 0 };

    // Calculate viewport edge vectors
    const viewport_u = v.vec3{ .x = viewport_width, .y = 0, .z = 0 };
    const viewport_v = v.vec3{ .x = 0, .y = -viewport_height, .z = 0 };

    // Calculate horizontal + vertical vectors from pixel to pixel
    const pixel_delta_u = v.divide(&viewport_u, image_width);
    const pixel_delta_v = v.divide(&viewport_v, @as(f64, @floatFromInt(image_height)));

    // Calculate position of the upper left pixel
    var viewport_upper_left = v.subtract(&camera_center, &v.vec3{ .x = 0, .y = 0, .z = focal_length });
    viewport_upper_left = v.subtract(&viewport_upper_left, &v.divide(&viewport_u, 2));
    viewport_upper_left = v.subtract(&viewport_upper_left, &v.divide(&viewport_v, 2));

    const first_pixel_location = v.add(&viewport_upper_left, &v.multiply(&v.add(&pixel_delta_u, &pixel_delta_v), 0.5));

    // render
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        std.log.info("Scanline {} of {}.", .{ j, image_height });
        for (0..image_width) |i| {
            const delta_u = v.multiply(&pixel_delta_u, @as(f64, @floatFromInt(i)));
            const delta_v = v.multiply(&pixel_delta_v, @as(f64, @floatFromInt(j)));
            const pixel_center = v.add(&v.add(&delta_u, &delta_v), &first_pixel_location);

            const ray_direction = v.subtract(&pixel_center, &camera_center);

            const ray = r.ray{ .origin = camera_center, .direction = ray_direction };
            const pixel_color: c.color = rayColor(&ray, &world);

            try c.writeColor(stdout, &pixel_color);
        }
    }

    std.log.info("Complete!", .{});

    try bw.flush();
}
