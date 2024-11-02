const std = @import("std");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const a = @import("aabb.zig");
const vec = @import("vec3.zig");
const interval = @import("interval.zig");

pub const Translate = struct {
    object: *const h.Hittable,
    offset: vec.vec3,
    box: a.AABB = undefined,

    pub fn initBoundingBox(self: *Translate) void {
        var box = self.object.boundingBox();
        self.box = box.addOffset(&self.offset);
    }

    pub fn boundingBox(self: Translate) a.AABB {
        return self.box;
    }

    pub fn hit(self: Translate, ray: *const r.ray, ray_t: interval.Interval, record: *h.HitRecord) bool {
        const offset_ray = r.ray{
            .origin = vec.subtract(&ray.origin, &self.offset),
            .direction = ray.direction,
            .time = ray.time,
        };

        if (!self.object.hit(&offset_ray, ray_t, record)) return false;

        record.point = vec.add(&record.point, &self.offset);

        return true;
    }
};
pub const RotateY = struct {
    object: *const h.Hittable,
    sin_theta: f64 = undefined,
    cos_theta: f64 = undefined,
    box: a.AABB = undefined,

    pub fn init(self: *RotateY, angle: f64) void {
        const radians: f64 = std.math.degreesToRadians(angle);
        self.sin_theta = std.math.sin(radians);
        self.cos_theta = std.math.cos(radians);
        self.box = self.object.boundingBox();

        var min = vec.point3{ .x = std.math.inf(f64), .y = std.math.inf(f64), .z = std.math.inf(f64) };
        var max = vec.point3{ .x = -std.math.inf(f64), .y = -std.math.inf(f64), .z = std.math.inf(f64) };

        for (0..2) |i| {
            for (0..2) |j| {
                for (0..2) |k| {
                    const f_i: f64 = @floatFromInt(i);
                    const f_j: f64 = @floatFromInt(j);
                    const f_k: f64 = @floatFromInt(k);

                    const x = f_i * self.box.x.max + (1 - f_i) * self.box.x.min;
                    const y = f_j * self.box.y.max + (1 - f_j) * self.box.y.min;
                    const z = f_k * self.box.z.max + (1 - f_k) * self.box.z.min;

                    const new_x = self.cos_theta * x + self.sin_theta * z;
                    const new_z = -self.sin_theta * x + self.cos_theta * z;

                    const tester = vec.vec3{ .x = new_x, .y = y, .z = new_z };

                    for (0..3) |c| {
                        const tester_val = vec.getByIndex(&tester, c);

                        vec.setByIndex(&min, @min(vec.getByIndex(&min, c), tester_val), c);
                        vec.setByIndex(&max, @max(vec.getByIndex(&max, c), tester_val), c);
                    }
                }
            }
        }
        self.box = a.AABB{};
        self.box.initPoints(&min, &max);
    }

    pub fn boundingBox(self: RotateY) a.AABB {
        return self.box;
    }

    pub fn hit(self: RotateY, ray: *const r.ray, ray_t: interval.Interval, record: *h.HitRecord) bool {

        // Transform ray from world space to object space

        const origin = vec.point3{
            .x = (self.cos_theta * ray.origin.x) - (self.sin_theta * ray.origin.z),
            .y = ray.origin.y,
            .z = (self.sin_theta * ray.origin.x) + (self.cos_theta * ray.origin.z),
        };

        const direction = vec.vec3{
            .x = (self.cos_theta * ray.direction.x) - (self.sin_theta * ray.direction.z),
            .y = ray.direction.y,
            .z = (self.sin_theta * ray.direction.x) + (self.cos_theta * ray.direction.z),
        };

        const rotated_ray = r.ray{
            .origin = origin,
            .direction = direction,
            .time = ray.time,
        };

        // Determine if intersection exists in object space

        if (!self.object.hit(&rotated_ray, ray_t, record)) return false;

        // Transform intersection from object space back to world space

        record.point = vec.point3{
            .x = (self.cos_theta * record.point.x) + (self.sin_theta * record.point.z),
            .y = record.point.y,
            .z = (-self.sin_theta * record.point.x) + (self.cos_theta * record.point.z),
        };

        record.normal = vec.vec3{
            .x = (self.cos_theta * record.normal.x) + (self.sin_theta * record.normal.z),
            .y = record.normal.y,
            .z = (-self.sin_theta * record.normal.x) + (self.cos_theta * record.normal.z),
        };

        return true;
    }
};
