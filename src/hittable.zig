const std = @import("std");
const vec = @import("vec3.zig");
const r = @import("ray.zig");
const i = @import("interval.zig");
const m = @import("material.zig");
const a = @import("aabb.zig");
const b = @import("bvh.zig");

pub const HitRecord = struct {
    point: vec.point3,
    normal: vec.vec3,
    mat: m.Material,
    t: f64,
    front_face: bool,
    // texture coords
    u: f64,
    v: f64,

    pub fn setFaceNormal(self: *HitRecord, ray: *const r.ray, outward_normal: *const vec.vec3) void {
        // Set hit record with normal vector
        // outward_normal assumed to be a unit vector

        self.front_face = vec.dotProduct(&ray.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal.* else vec.multiply(outward_normal, -1);
    }
};

fn getSphereUV(point: *const vec.point3, u: *f64, v: *f64) void {
    const theta = std.math.acos(-point.y);
    const phi = std.math.atan2(-point.z, point.x) + std.math.pi;

    u.* = phi / (2 * std.math.pi);
    v.* = theta / std.math.pi;
}

pub const Sphere = struct {
    center: r.ray,
    radius: f64,
    mat: m.Material,
    box: a.AABB = a.AABB{},

    pub fn initBoundingBox(self: *Sphere) void {
        // check if stationary
        const dir = self.center.direction;
        const r_vec = vec.vec3{ .x = self.radius, .y = self.radius, .z = self.radius };

        if (dir.x == 0 and dir.y == 0 and dir.z == 0) {
            self.box.initPoints(&vec.subtract(&self.center.origin, &r_vec), &vec.add(&self.center.origin, &r_vec));
        } else {
            const point0 = r.at(&self.center, 0);
            const point1 = r.at(&self.center, 1);
            var box1 = a.AABB{};
            box1.initPoints(&vec.subtract(&point0, &r_vec), &vec.add(&point0, &r_vec));
            var box2 = a.AABB{};
            box2.initPoints(&vec.subtract(&point1, &r_vec), &vec.add(&point1, &r_vec));
            self.box.initBoxes(&box1, &box2);
        }
    }

    pub fn boundingBox(self: Sphere) a.AABB {
        return self.box;
    }

    pub fn hit(self: Sphere, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        const current_center = r.at(&self.center, ray.time);
        const oc = vec.subtract(&current_center, &ray.origin);
        const lsq = vec.lengthSquared(&ray.direction);
        const h = vec.dotProduct(&ray.direction, &oc);
        const c_var = vec.lengthSquared(&oc) - (self.radius * self.radius);
        const discriminant = (h * h) - (lsq * c_var);

        if (discriminant < 0) {
            return false;
        }

        const sqrtd = std.math.sqrt(discriminant);
        // find nearest root that lies in acceptable range

        var root = (h - sqrtd) / lsq;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / lsq;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        record.t = root;
        record.point = r.at(ray, record.t);
        const outward_normal = vec.divide(&vec.subtract(&record.point, &current_center), self.radius);
        record.setFaceNormal(ray, &outward_normal);
        const p_u: *f64 = &record.u;
        const p_v: *f64 = &record.v;
        getSphereUV(&outward_normal, p_u, p_v);
        record.mat = self.mat;

        return true;
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Hittable) = undefined,
    box: a.AABB = a.AABB{},

    pub fn initBoundingBox(self: *const HittableList) void {
        _ = self;
    }

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

    pub fn pushSphere(self: *HittableList, sphere: Sphere) !void {
        var object = Hittable{ .sphere = sphere };
        object.sphere.initBoundingBox();
        try self.objects.append(object);
        self.box.initBoxes(&self.box, &object.boundingBox());
    }

    pub fn push(self: *HittableList, object: *Hittable) !void {
        try self.objects.append(object);
        switch (object.*) {
            .sphere => object.sphere.initBoundingBox(),
            else => {},
        }
        //object.initBoundingBox();
        self.box.initBoxes(&self.box, &object.boundingBox());
    }

    pub fn getLen(self: HittableList) usize {
        return self.objects.items.len;
    }

    pub fn boundingBox(self: HittableList) a.AABB {
        return self.box;
    }

    pub fn hit(self: HittableList, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        var temp_record = HitRecord{ .point = vec.point3{}, .normal = vec.vec3{}, .mat = m.Material{ .none = m.None{} }, .t = 0, .front_face = false, .u = 0, .v = 0 };
        const p_record: *HitRecord = &temp_record;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            const interval = i.Interval{ .min = ray_t.min, .max = closest_so_far };
            if (object.hit(ray, interval, p_record)) {
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
    bvh: b.BVHNode,

    pub fn hit(self: Hittable, ray: *const r.ray, ray_t: i.Interval, record: *HitRecord) bool {
        switch (self) {
            inline else => |case| return case.hit(ray, ray_t, record),
        }
    }

    pub fn boundingBox(self: Hittable) a.AABB {
        switch (self) {
            inline else => |case| return case.boundingBox(),
        }
    }
};
