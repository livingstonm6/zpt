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
        self.box = self.object.boundingBox().addOffset(&self.offset);
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
