const i = @import("interval.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");

pub const AABB = struct {
    x: i.Interval = i.empty,
    y: i.Interval = i.empty,
    z: i.Interval = i.empty,

    pub fn initIntervals(self: *AABB, int1: i.Interval, int2: i.Interval, int3: i.Interval) void {
        self.x = int1;
        self.y = int2;
        self.z = int3;
    }

    pub fn initPoints(self: *AABB, a: *const v.point3, b: *const v.point3) void {
        self.x = if (a.x <= b.x) i.Interval{ .min = a.x, .max = b.x } else i.Inteval{ .min = b.x, .max = a.x };
        self.y = if (a.y <= b.y) i.Interval{ .min = a.y, .max = b.y } else i.Inteval{ .min = b.y, .max = a.y };
        self.z = if (a.z <= b.z) i.Interval{ .min = a.z, .max = b.z } else i.Inteval{ .min = b.z, .max = a.z };
    }

    pub fn initBoxes(self: *AABB, box1: *const AABB, box2: *const AABB) void {
        self.x = i.fromIntervals(&box1.x, &box2.x);
        self.y = i.fromIntervals(&box1.y, &box2.y);
        self.z = i.fromIntervals(&box1.z, &box2.z);
    }

    pub fn axisInterval(self: AABB, n: usize) i.Interval {
        if (n == 1) return self.y;
        if (n == 2) return self.z;
        return self.x;
    }

    pub fn hit(self: AABB, ray: *const r.ray, ray_t: i.Interval) bool {
        for (0..3) |axis| {
            const ax = self.axisInterval(axis);
            const ad_inv = 1.0 / v.getByIndex(&ray.direction, axis);

            const t0 = (ax.min - v.getByIndex(&ray.origin, axis)) * ad_inv;
            const t1 = (ax.max - v.getByIndex(&ray.origin, axis)) * ad_inv;

            if (t0 < t1) {
                if (t0 > ray_t.min) ray_t.min = t0;
                if (t1 < ray_t.max) ray_t.max = t1;
            } else {
                if (t1 > ray_t.min) ray_t.min = t1;
                if (t0 < ray_t.max) ray_t.max = t0;
            }

            if (ray_t.max <= ray_t.min) {
                return false;
            }
        }
        return true;
    }
};
