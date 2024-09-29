const r = @import("ray.zig");
const h = @import("hittable.zig");
const c = @import("color.zig");
const v = @import("vec3.zig");

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

    pub fn scatter(self: Material, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        switch (self) {
            inline else => |case| return case.scatter(ray_in, record, attenuation, scattered),
        }
    }
};
