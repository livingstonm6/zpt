const std = @import("std");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const c = @import("color.zig");
const vec = @import("vec3.zig");
const util = @import("util.zig");
const t = @import("texture.zig");

pub const Lambertian = struct {
    texture: t.Texture = undefined,

    pub fn initAlbedo(self: *Lambertian, albedo: c.color) void {
        self.texture = t.Texture{ .solidColor = t.SolidColor{ .albedo = albedo } };
    }

    pub fn initTexture(self: *Lambertian, texture: t.Texture) void {
        self.texture = texture;
    }

    pub fn scatter(self: Lambertian, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        var scattered_direction = vec.add(&record.normal, &try vec.randomUnit());

        if (vec.nearZero(&scattered_direction)) {
            scattered_direction = record.normal;
        }

        scattered.* = r.ray{ .origin = record.point, .direction = scattered_direction, .time = ray_in.time };
        attenuation.* = try self.texture.value(record.u, record.v, &record.point);
        return true;
    }
};

pub const DiffuseLight = struct {
    texture: t.Texture = undefined,

    pub fn initColor(self: *DiffuseLight, color: c.color) void {
        self.texture = t.Texture{ .solidColor = t.SolidColor{ .albedo = color } };
    }

    pub fn initTexture(self: *DiffuseLight, texture: t.Texture) void {
        self.texture = texture;
    }

    pub fn emitted(self: DiffuseLight, u: f64, v: f64, p: *const vec.point3) !c.color {
        return try self.texture.value(u, v, p);
    }

    pub fn scatter(self: DiffuseLight, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        _ = .{ self, ray_in, record, attenuation, scattered };
        return false;
    }
};

pub const Metal = struct {
    albedo: c.color,
    fuzz: f64 = 1.0,

    pub fn scatter(self: Metal, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        var reflected = vec.reflect(&ray_in.direction, &record.normal);
        reflected = vec.unit(&reflected);
        reflected = vec.add(&reflected, &vec.multiply(&try vec.randomUnit(), self.fuzz));
        scattered.* = r.ray{ .origin = record.point, .direction = reflected, .time = ray_in.time };
        attenuation.* = self.albedo;
        return vec.dotProduct(&scattered.direction, &record.normal) > 0;
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
        const unit_direction = vec.unit(&ray_in.direction);

        var cos_theta = vec.dotProduct(&vec.multiply(&unit_direction, -1), &record.normal);
        if (cos_theta > 1.0) {
            cos_theta = 1.0;
        }
        const sin_theta = std.math.sqrt(1.0 - (cos_theta * cos_theta));

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: vec.vec3 = undefined;
        if (cannot_refract or self.reflectance(cos_theta, ri) > try util.randomF64()) {
            direction = vec.reflect(&unit_direction, &record.normal);
        } else {
            direction = vec.refract(&unit_direction, &record.normal, ri);
        }

        scattered.* = r.ray{ .origin = record.point, .direction = direction, .time = ray_in.time };
        return true;
    }
};

pub const None = struct {
    pub fn scatter(self: None, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        _ = .{ self, ray_in, record, attenuation, scattered };
        return false;
    }
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    diffuseLight: DiffuseLight,
    metal: Metal,
    none: None,
    dielectric: Dielectric,

    pub fn scatter(self: Material, ray_in: *const r.ray, record: h.HitRecord, attenuation: *c.color, scattered: *r.ray) !bool {
        switch (self) {
            inline else => |case| return case.scatter(ray_in, record, attenuation, scattered),
        }
    }

    pub fn emitted(self: Material, u: f64, v: f64, p: *const vec.point3) !c.color {
        switch (self) {
            .diffuseLight => |case| return try case.emitted(u, v, p),
            inline else => return c.color{ .x = 0, .y = 0, .z = 0 },
        }
    }
};
