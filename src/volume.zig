const std = @import("std");
const h = @import("hittable.zig");
const m = @import("material.zig");
const t = @import("texture.zig");
const c = @import("color.zig");
const r = @import("ray.zig");
const i = @import("interval.zig");
const vec = @import("vec3.zig");
const util = @import("util.zig");
const a = @import("aabb.zig");

pub const ConstantMedium = struct {
    boundary: *h.Hittable,
    neg_inv_density: f64 = undefined,
    phase_function: m.Material = undefined,

    pub fn initAlbedo(self: *ConstantMedium, density: f64, albedo: *const c.color) void {
        self.neg_inv_density = -1 / density;
        self.phase_function = m.Material{ .isotropic = m.Isotropic{} };
        self.phase_function.isotropic.initColor(albedo.*);
    }

    pub fn initTexture(self: *ConstantMedium, density: f64, tex: t.Texture) void {
        self.neg_inv_density = -1 / density;
        self.phase_function = m.Material{ .isotropic = m.Isotropic{} };
        self.phase_function.isotropic.initTexture(tex);
    }

    pub fn boundingBox(self: ConstantMedium) a.AABB {
        return self.boundary.boundingBox();
    }

    pub fn hit(self: ConstantMedium, ray: *const r.ray, ray_t: i.Interval, record: *h.HitRecord) bool {
        var record1 = h.HitRecord{ .front_face = undefined, .mat = undefined, .normal = undefined, .point = undefined, .t = undefined, .u = undefined, .v = undefined };
        var record2 = record1;

        if (!self.boundary.hit(ray, i.universe, &record1)) return false;
        if (!self.boundary.hit(ray, i.Interval{ .min = record1.t + 0.0001, .max = std.math.inf(f64) }, &record2)) return false;

        if (record1.t < ray_t.min) record1.t = ray_t.min;
        if (record2.t > ray_t.max) record2.t = ray_t.max;

        if (record1.t >= record2.t) return false;

        if (record1.t < 0) record1.t = 0;

        const length = vec.length(&ray.direction);
        const distance_inside_boundary = (record2.t - record1.t) * length;
        const hit_distance = self.neg_inv_density * std.math.log(f64, util.randomF64() catch 0.0, std.math.e);

        if (hit_distance > distance_inside_boundary) return false;

        record.t = record1.t + (hit_distance / length);
        record.point = r.at(ray, record.t);

        record.normal = vec.vec3{ .x = 1, .y = 0, .z = 0 };
        record.front_face = true;
        record.mat = self.phase_function;

        return true;
    }
};
