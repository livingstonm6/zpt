const std = @import("std");
const v = @import("vec3.zig");
const r = @import("ray.zig");
const i = @import("interval.zig");
const m = @import("material.zig");

pub const HitRecord = struct {
    point: v.point3,
    normal: v.vec3,
    mat: *const m.Material,
    t: f64,
    front_face: bool,

    pub fn setFaceNormal(self: *HitRecord, ray: *const r.ray, outward_normal: *const v.vec3) void {
        // Set hit record with normal vector
        // outward_normal assumed to be a unit vector

        self.front_face = v.dotProduct(&ray.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal.* else v.multiply(outward_normal, -1);
    }
};

pub const Sphere = struct {
    center: r.ray,
    radius: f64,
    mat: m.Material,

    pub fn hit(self: Sphere, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        const current_center = r.at(&self.center, ray.time);
        const oc = v.subtract(&current_center, &ray.origin);
        const a = v.lengthSquared(&ray.direction);
        const h = v.dotProduct(&ray.direction, &oc);
        const c_var = v.lengthSquared(&oc) - (self.radius * self.radius);
        const discriminant = (h * h) - (a * c_var);

        if (discriminant < 0) {
            return false;
        }

        const sqrtd = std.math.sqrt(discriminant);
        // find nearest root that lies in acceptable range

        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        record.t = root;
        record.point = r.at(ray, record.t);
        const outward_normal = v.divide(&v.subtract(&record.point, &current_center), self.radius);
        record.setFaceNormal(ray, &outward_normal);
        record.mat = &self.mat;

        return true;
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Hittable) = undefined,

    pub fn init(self: *HittableList, allocator: std.mem.Allocator) void {
        self.objects = std.ArrayList(Hittable).init(allocator);
    }

    pub fn deinit(self: HittableList) void {
        self.objects.deinit();
    }

    pub fn clear(self: HittableList) void {
        const len = self.objects.items.len;
        for (0..len) |_| {
            self.objects.pop();
        }
    }

    pub fn push(self: *HittableList, object: Hittable) !void {
        try self.objects.append(object);
    }

    pub fn getLen(self: HittableList) usize {
        return self.objects.len;
    }

    pub fn hit(self: HittableList, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        var temp_record = HitRecord{
            .point = undefined,
            .normal = undefined,
            .mat = undefined,
            .t = undefined,
            .front_face = undefined,
        };
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(ray, i.Interval{ .min = ray_t.min, .max = closest_so_far }, &temp_record)) {
                hit_anything = true;
                closest_so_far = temp_record.t;
                record.* = temp_record;
            }
        }
        return hit_anything;
    }
};

// Interface
pub const Hittable = union(enum) {
    sphere: Sphere,
    hittableList: HittableList,

    pub fn hit(self: Hittable, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        switch (self) {
            inline else => |case| return case.hit(ray, ray_t, record),
        }
    }
};
