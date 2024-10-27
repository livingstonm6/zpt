const std = @import("std");
const vec = @import("vec3.zig");
const m = @import("material.zig");
const aabb = @import("aabb.zig");
const r = @import("ray.zig");
const h = @import("hittable.zig");
const i = @import("interval.zig");
const q = @import("quad.zig");

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

pub fn box(a: *const vec.point3, b: *const vec.point3, mat: m.Material, allocator: std.mem.Allocator) !h.HittableList {

    // Caller must call deinit() on the list returned by this function

    var sides = h.HittableList{};
    sides.init(allocator);

    const min = vec.point3{
        .x = @min(a.x, b.x),
        .y = @min(a.y, b.y),
        .z = @min(a.z, b.z),
    };

    const max = vec.point3{
        .x = @max(a.x, b.x),
        .y = @max(a.y, b.y),
        .z = @max(a.z, b.z),
    };

    const dx = vec.vec3{
        .x = max.x - min.x,
        .y = 0,
        .z = 0,
    };

    const dy = vec.vec3{
        .x = 0,
        .y = max.y - min.y,
        .z = 0,
    };

    const dz = vec.vec3{
        .x = 0,
        .y = 0,
        .z = max.z - min.z,
    };

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = min.x,
            .y = min.y,
            .z = max.z,
        },
        .u = dx,
        .v = dy,
        .mat = mat,
    });

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = max.x,
            .y = min.y,
            .z = max.z,
        },
        .u = vec.multiply(&dz, -1),
        .v = dy,
        .mat = mat,
    });

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = max.x,
            .y = min.y,
            .z = min.z,
        },
        .u = vec.multiply(&dx, -1),
        .v = dy,
        .mat = mat,
    });

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = min.x,
            .y = min.y,
            .z = min.z,
        },
        .u = dz,
        .v = dy,
        .mat = mat,
    });

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = min.x,
            .y = max.y,
            .z = max.z,
        },
        .u = dx,
        .v = vec.multiply(&dz, -1),
        .mat = mat,
    });

    try sides.pushQuad(q.Quad{
        .q = vec.point3{
            .x = min.x,
            .y = min.y,
            .z = min.z,
        },
        .u = dx,
        .v = dz,
        .mat = mat,
    });

    return sides;
}
