const std = @import("std");
const h = @import("hittable.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");
const c = @import("color.zig");
const util = @import("util.zig");
const interval = @import("interval.zig");

pub const Camera = struct {
    aspect_ratio: f64 = 16.0 / 9.0,
    image_width: u16 = 400,
    samples_per_pixel: u8 = 10,
    max_recursion_depth: u8 = 10,
    pixel_samples_scale: f64 = undefined,
    image_height: u16 = undefined,
    center: v.point3 = undefined,
    pixel00_loc: v.point3 = undefined,
    pixel_delta_u: v.vec3 = undefined,
    pixel_delta_v: v.vec3 = undefined,

    fn init(self: *Camera) void {
        self.image_width = 400;
        self.pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(self.samples_per_pixel));

        // Calculate image height (min 1)
        self.image_height = @as(u16, @intFromFloat(@as(f64, @floatFromInt(self.image_width)) / self.aspect_ratio));
        if (self.image_height < 1) self.image_height = 1;

        // Camera
        const focal_length: f64 = 1.0;
        const viewport_height: f64 = 2.0;
        const width_over_height: f64 = @as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height));
        const viewport_width: f64 = viewport_height * width_over_height;
        self.center = v.point3{ .x = 0, .y = 0, .z = 0 };

        // Calculate viewport edge vectors
        const viewport_u = v.vec3{ .x = viewport_width, .y = 0, .z = 0 };
        const viewport_v = v.vec3{ .x = 0, .y = -viewport_height, .z = 0 };

        // Calculate horizontal + vertical vectors from pixel to pixel
        self.pixel_delta_u = v.divide(&viewport_u, @as(f64, @floatFromInt(self.image_width)));
        self.pixel_delta_v = v.divide(&viewport_v, @as(f64, @floatFromInt(self.image_height)));

        // Calculate position of the upper left pixel
        var viewport_upper_left = v.subtract(&self.center, &v.vec3{ .x = 0, .y = 0, .z = focal_length });
        viewport_upper_left = v.subtract(&viewport_upper_left, &v.divide(&viewport_u, 2));
        viewport_upper_left = v.subtract(&viewport_upper_left, &v.divide(&viewport_v, 2));

        self.pixel00_loc = v.add(&viewport_upper_left, &v.multiply(&v.add(&self.pixel_delta_u, &self.pixel_delta_v), 0.5));
    }

    fn rayColor(self: *Camera, ray: *const r.ray, world: *const h.Hittable, depth: u8) !c.color {
        if (depth <= 0) {
            return c.color{ .x = 0, .y = 0, .z = 0 };
        }

        var record = h.HitRecord{
            .point = undefined,
            .normal = undefined,
            .t = undefined,
            .front_face = undefined,
        };
        if (world.hit(ray, interval.Interval{ .min = 0.001, .max = std.math.inf(f64) }, &record)) {
            const rand = try v.randomOnHemisphere(&record.normal);
            const bounce_direction = v.add(&record.normal, &rand);
            const bounce_ray = r.ray{ .origin = record.point, .direction = bounce_direction };
            const ray_color = try self.rayColor(&bounce_ray, world, depth - 1);
            return v.multiply(&ray_color, 0.5);

            //return v.multiply(&v.add(&record.normal, &v.vec3{ .x = 1, .y = 1, .z = 1 }), 0.5);
        }

        // lerp
        const unit_direction = v.unit(&ray.direction);
        const a = 0.5 * (unit_direction.y + 1.0);

        const term1 = v.multiply(&v.vec3{ .x = 1.0, .y = 1.0, .z = 1.0 }, (1.0 - a));
        const term2 = v.multiply(&v.vec3{ .x = 0.5, .y = 0.7, .z = 1.0 }, a);
        return v.add(&term1, &term2);
    }

    fn sampleSquare(self: Camera) !v.vec3 {
        _ = self;
        const rand1 = try util.randomF64();
        const rand2 = try util.randomF64();
        return v.vec3{
            .x = rand1 - 0.5,
            .y = rand2 - 0.5,
            .z = 0,
        };
    }

    fn getRay(self: Camera, i: f64, j: f64) !r.ray {
        const offset = try self.sampleSquare();
        var pixel_sample = self.pixel00_loc;
        const delta_u = v.multiply(&self.pixel_delta_u, (i + offset.x));
        const delta_v = v.multiply(&self.pixel_delta_v, (j + offset.y));
        pixel_sample = v.add(&pixel_sample, &delta_u);
        pixel_sample = v.add(&pixel_sample, &delta_v);
        const ray_origin = self.center;
        const ray_direction = v.subtract(&pixel_sample, &ray_origin);

        return r.ray{
            .origin = ray_origin,
            .direction = ray_direction,
        };
    }

    pub fn render(self: *Camera, world: *const h.Hittable) !void {
        self.init();

        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        try stdout.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            std.log.info("Scanline {} of {}.", .{ j, self.image_height });
            for (0..self.image_width) |i| {
                var pixel_color = c.color{ .x = 0, .y = 0, .z = 0 };
                for (0..self.samples_per_pixel) |sample| {
                    _ = sample;
                    const i_float = @as(f64, @floatFromInt(i));
                    const j_float = @as(f64, @floatFromInt(j));
                    const ray = try self.getRay(i_float, j_float);
                    const ray_color = try self.rayColor(&ray, world, self.max_recursion_depth);
                    pixel_color = v.add(&pixel_color, &ray_color);
                }

                pixel_color = v.multiply(&pixel_color, self.pixel_samples_scale);

                try c.writeColor(stdout, &pixel_color);
            }
        }

        std.log.info("Complete!", .{});

        try bw.flush();
    }
};
