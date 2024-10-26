const std = @import("std");
const vec = @import("vec3.zig");
const m = @import("material.zig");
const aabb = @import("aabb.zig");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const i = @import("interval.zig");

pub const Quad = struct {
    q: vec.point3,
    v: vec.vec3,
    u: vec.vec3,
    mat: m.Material,
    box: aabb.AABB = aabb.AABB{},
    normal: vec.vec3 = undefined,
    D: f64 = undefined,
    w: vec.vec3 = undefined,

    pub fn init(self: *Quad) void {
        const n = vec.cross(&self.u, &self.v);
        self.normal = vec.unit(&n);
        self.D = vec.dotProduct(&self.normal, &self.q);
        self.w = vec.divide(&n, vec.dotProduct(&n, &n));
        self.setBoundingBox();
    }

    pub fn setBoundingBox(self: *Quad) void {
        var box1 = aabb.AABB{};
        box1.initPoints(&self.q, &vec.add(&vec.add(&self.q, &self.u), &self.v));
        var box2 = aabb.AABB{};
        box2.initPoints(&vec.add(&self.q, &self.u), &vec.add(&self.q, &self.u));
        self.box.initBoxes(&box1, &box2);
    }

    pub fn boundingBox(self: Quad) aabb.AABB {
        return self.box;
    }

    fn isInterior(self: Quad, a: f64, b: f64, record: *h.HitRecord) bool {
        _ = self;
        const unit_interval = i.Interval{ .min = 0, .max = 1 };

        if (!unit_interval.contains(a) or !unit_interval.contains(b)) return false;

        record.u = a;
        record.v = b;
        return true;
    }

    pub fn hit(self: Quad, ray: *const r.ray, ray_t: i.Interval, record: *h.HitRecord) bool {
        _ = .{ self, ray, ray_t, record };

        const denom = vec.dotProduct(&self.normal, &ray.direction);
        // False if ray is parallel to plane
        if (@abs(denom) < 1e-8) return false;

        // False if t is outside ray interval
        const t = (self.D - vec.dotProduct(&self.normal, &ray.origin)) / denom;
        if (!ray_t.contains(t)) return false;

        // Determine if hit point lies within planar shape
        const intersection = r.at(ray, t);
        const planar_hitpoint_vector = vec.subtract(&intersection, &self.q);
        const alpha = vec.dotProduct(&self.w, &vec.cross(&planar_hitpoint_vector, &self.v));
        const beta = vec.dotProduct(&self.w, &vec.cross(&self.u, &planar_hitpoint_vector));
        if (!self.isInterior(alpha, beta, record)) return false;

        // Hit
        record.t = t;
        record.point = intersection;
        record.mat = self.mat;
        record.setFaceNormal(ray, &self.normal);

        return true;
    }
};
