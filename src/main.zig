const std = @import("std");
const c = @import("color.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");

fn hitSphere(center: *const v.point3, radius: f64, ray: *const r.ray) f64 {
    const oc = v.subtract(center, &ray.origin);
    const a = v.dotProduct(&ray.direction, &ray.direction);
    const b = -2.0 * v.dotProduct(&ray.direction, &oc);
    const c_var = v.dotProduct(&oc, &oc) - (radius * radius);
    const discriminant = (b * b) - (4 * a * c_var);

    if (discriminant < 0) {
        return -1.0;
    }

    return (-b - std.math.sqrt(discriminant)) / (2.0 * a);
}

fn rayColor(ray: *const r.ray) c.color {
    const t = hitSphere(&v.point3{ .x = 0, .y = 0, .z = -1 }, 0.5, ray);
    if (t > 0.0) {
        const n = v.unit(&v.subtract(&r.at(ray, t), &v.vec3{ .x = 0, .y = 0, .z = -1 }));
        return v.multiply(&c.color{ .x = n.x + 1, .y = n.y + 1, .z = n.z + 1 }, 0.5);
    }

    // lerp
    const unit_direction = v.unit(&ray.direction);
    const a = 0.5 * (unit_direction.y + 1.0);

    const term1 = v.multiply(&v.vec3{ .x = 1.0, .y = 1.0, .z = 1.0 }, (1.0 - a));
    const term2 = v.multiply(&v.vec3{ .x = 0.5, .y = 0.7, .z = 1.0 }, a);
    return v.add(&term1, &term2);
}

pub fn main() !void {
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u16 = 400;

    var image_height: u16 = image_width / aspect_ratio;
    if (image_height < 0) image_height = 0;

    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const width_over_height: f64 = @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const viewport_width: f64 = viewport_height * width_over_height;
    const camera_center = v.point3{ .x = 0, .y = 0, .z = 0 };

    const viewport_u = v.vec3{ .x = viewport_width, .y = 0, .z = 0 };
    const viewport_v = v.vec3{ .x = 0, .y = -viewport_height, .z = 0 };

    const pixel_delta_u = v.divide(&viewport_u, image_width);
    const pixel_delta_v = v.divide(&viewport_v, @as(f64, @floatFromInt(image_height)));

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
            const pixel_color: c.color = rayColor(&ray);

            try c.writeColor(stdout, &pixel_color);
        }
    }

    std.log.info("Complete!", .{});

    try bw.flush();
}

// pub fn main() !void {
//     // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
//     std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

//     // stdout is for the actual output of your application, for example if you
//     // are implementing gzip, then only the compressed bytes should be sent to
//     // stdout, not any debugging messages.
//     const stdout_file = std.io.getStdOut().writer();
//     var bw = std.io.bufferedWriter(stdout_file);
//     const stdout = bw.writer();

//     try stdout.print("Run `zig build test` to run the tests.\n", .{});

//     try bw.flush(); // don't forget to flush!
// }

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
