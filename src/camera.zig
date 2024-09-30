const std = @import("std");
const h = @import("hittable.zig");
const vec = @import("vec3.zig");
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
    center: vec.point3 = undefined,
    pixel00_loc: vec.point3 = undefined,
    pixel_delta_u: vec.vec3 = undefined,
    pixel_delta_v: vec.vec3 = undefined,
    // Camera position
    vertical_fov: f64 = 90,
    look_from: vec.point3 = vec.point3{},
    look_at: vec.point3 = vec.point3{ .x = 0, .y = 0, .z = -1 },
    v_up: vec.vec3 = vec.vec3{ .x = 0, .y = 1, .z = 0 },
    u: vec.vec3 = undefined,
    v: vec.vec3 = undefined,
    w: vec.vec3 = undefined,
    // Depth of field
    dof_angle: f64 = 0,
    focus_dist: f64 = 10,
    dof_disk_u: vec.vec3 = undefined,
    dof_disk_v: vec.vec3 = undefined,

    fn init(self: *Camera) void {
        self.pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(self.samples_per_pixel));

        self.center = self.look_from;

        // Calculate image height (min 1)
        self.image_height = @as(u16, @intFromFloat(@as(f64, @floatFromInt(self.image_width)) / self.aspect_ratio));
        if (self.image_height < 1) self.image_height = 1;

        // Camera
        const theta = std.math.degreesToRadians(self.vertical_fov);
        const h_var = std.math.tan(theta / 2);
        const viewport_height: f64 = 2.0 * h_var * self.focus_dist;
        const width_over_height: f64 = @as(f64, @floatFromInt(self.image_width)) / @as(f64, @floatFromInt(self.image_height));
        const viewport_width: f64 = viewport_height * width_over_height;

        // Calculate u, v, w unit basis vectors for the camera coordinate frame
        self.w = vec.unit(&vec.subtract(&self.look_from, &self.look_at));
        self.u = vec.unit(&vec.cross(&self.v_up, &self.w));
        self.v = vec.cross(&self.w, &self.u);

        // Calculate viewport edge vectors
        const viewport_u = vec.multiply(&self.u, viewport_width);
        const viewport_v = vec.multiply(&vec.multiply(&self.v, -1), viewport_height);

        // Calculate horizontal + vertical vectors from pixel to pixel
        self.pixel_delta_u = vec.divide(&viewport_u, @as(f64, @floatFromInt(self.image_width)));
        self.pixel_delta_v = vec.divide(&viewport_v, @as(f64, @floatFromInt(self.image_height)));

        // Calculate position of the upper left pixel
        var viewport_upper_left = vec.subtract(&self.center, &vec.multiply(&self.w, self.focus_dist));
        viewport_upper_left = vec.subtract(&viewport_upper_left, &vec.divide(&viewport_u, 2));
        viewport_upper_left = vec.subtract(&viewport_upper_left, &vec.divide(&viewport_v, 2));
        self.pixel00_loc = vec.add(&viewport_upper_left, &vec.multiply(&vec.add(&self.pixel_delta_u, &self.pixel_delta_v), 0.5));

        // Calculate camera defocus disk basis vectors
        const dof_radius = self.focus_dist * std.math.tan(std.math.degreesToRadians(self.dof_angle / 2));
        self.dof_disk_u = vec.multiply(&self.u, dof_radius);
        self.dof_disk_v = vec.multiply(&self.v, dof_radius);
    }

    fn rayColor(self: *Camera, ray: *const r.ray, world: *const h.Hittable, depth: u8) !c.color {
        if (depth <= 0) {
            return c.color{ .x = 0, .y = 0, .z = 0 };
        }

        var record = h.HitRecord{
            .point = undefined,
            .normal = undefined,
            .mat = undefined,
            .t = undefined,
            .front_face = undefined,
        };
        if (world.hit(ray, interval.Interval{ .min = 0.001, .max = std.math.inf(f64) }, &record)) {
            var scattered = r.ray{};
            var attenuation = c.color{};
            const p_scat: *r.ray = &scattered;
            const p_att: *c.color = &attenuation;
            if (try record.mat.scatter(ray, record, p_att, p_scat)) {
                const ray_color = try self.rayColor(p_scat, world, depth - 1);
                return vec.vecMultiply(&ray_color, p_att);
            }
            return c.color{};
        }

        // lerp
        const unit_direction = vec.unit(&ray.direction);
        const a = 0.5 * (unit_direction.y + 1.0);

        const term1 = vec.multiply(&vec.vec3{ .x = 1.0, .y = 1.0, .z = 1.0 }, (1.0 - a));
        const term2 = vec.multiply(&vec.vec3{ .x = 0.5, .y = 0.7, .z = 1.0 }, a);
        return vec.add(&term1, &term2);
    }

    fn sampleSquare(self: Camera) !vec.vec3 {
        _ = self;
        const rand1 = try util.randomF64();
        const rand2 = try util.randomF64();
        return vec.vec3{
            .x = rand1 - 0.5,
            .y = rand2 - 0.5,
            .z = 0,
        };
    }

    fn getRay(self: Camera, i: f64, j: f64) !r.ray {
        const offset = try self.sampleSquare();
        var pixel_sample = self.pixel00_loc;
        const delta_u = vec.multiply(&self.pixel_delta_u, (i + offset.x));
        const delta_v = vec.multiply(&self.pixel_delta_v, (j + offset.y));
        pixel_sample = vec.add(&pixel_sample, &delta_u);
        pixel_sample = vec.add(&pixel_sample, &delta_v);
        const ray_origin = if (self.dof_angle <= 0) self.center else try self.dofDiskSample();
        const ray_direction = vec.subtract(&pixel_sample, &ray_origin);

        return r.ray{
            .origin = ray_origin,
            .direction = ray_direction,
        };
    }

    pub fn dofDiskSample(self: *const Camera) !vec.point3 {
        const p = try vec.randomInUnitDisk();
        var result = self.center;
        result = vec.add(&result, &vec.multiply(&self.dof_disk_u, p.x));
        result = vec.add(&result, &vec.multiply(&self.dof_disk_v, p.y));
        return result;
    }

    pub fn render(self: *Camera, world: *const h.Hittable) !void {
        const before = std.time.milliTimestamp();

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
                    pixel_color = vec.add(&pixel_color, &ray_color);
                }

                pixel_color = vec.multiply(&pixel_color, self.pixel_samples_scale);

                try c.writeColor(stdout, &pixel_color);
            }
        }
        const after = std.time.milliTimestamp();
        const time_ms = after - before;
        const time_s: f64 = @as(f64, @floatFromInt(time_ms)) / 1000.0;
        const time_m: f64 = time_s / 60.0;

        std.log.info("Completed in {}ms ({}s, {} minutes)!", .{ time_ms, time_s, time_m });

        try bw.flush();
    }
};
