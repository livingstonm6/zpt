const std = @import("std");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const c = @import("color.zig");
const v = @import("vec3.zig");
const util = @import("util.zig");

pub const Lambertian = struct {
    albedo: c.color,

    pub fn scatter(self: Lambertian, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        _ = ray_in;

        var scattered_direction = v.add(&record.normal, &try v.randomUnit());

        if (v.nearZero(&scattered_direction)) {
            scattered_direction = record.normal;
        }

        scattered.* = r.ray{ .origin = record.point, .direction = scattered_direction };
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: c.color,
    fuzz: f64 = 1.0,

    pub fn scatter(self: Metal, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        var reflected = v.reflect(&ray_in.direction, &record.normal);
        reflected = v.unit(&reflected);
        reflected = v.add(&reflected, &v.multiply(&try v.randomUnit(), self.fuzz));
        scattered.* = r.ray{ .origin = record.point, .direction = reflected };
        attenuation.* = self.albedo;
        return v.dotProduct(&scattered.direction, &record.normal) > 0;
    }
};

pub const Dielectric = struct {
    refraction_index: f64,

    fn reflectance(self: Dielectric, cosine: f64, refraction_index: f64) f64 {
        _ = self;
        // Schlick's approximation
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(f64, (1 - cosine), 5);
    }

    pub fn scatter(self: Dielectric, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        attenuation.* = c.color{ .x = 1.0, .y = 1.0, .z = 1.0 };
        const ri = if (record.front_face) (1.0 / self.refraction_index) else self.refraction_index;
        const unit_direction = v.unit(&ray_in.direction);

        var cos_theta = v.dotProduct(&v.multiply(&unit_direction, -1), &record.normal);
        if (cos_theta > 1.0) {
            cos_theta = 1.0;
        }
        const sin_theta = std.math.sqrt(1.0 - (cos_theta * cos_theta));

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: v.vec3 = undefined;
        if (cannot_refract or self.reflectance(cos_theta, ri) > try util.randomF64()) {
            direction = v.reflect(&unit_direction, &record.normal);
        } else {
            direction = v.refract(&unit_direction, &record.normal, ri);
        }

        scattered.* = r.ray{ .origin = record.point, .direction = direction };
        return true;
    }
};

pub const None = struct {
    albedo: c.color,

    pub fn scatter(self: None, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        _ = .{ self, ray_in, record, attenuation, scattered };
        return false;
    }
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    none: None,
    dielectric: Dielectric,

    pub fn scatter(self: Material, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        switch (self) {
            inline else => |case| return case.scatter(ray_in, record, attenuation, scattered),
        }
    }
};
