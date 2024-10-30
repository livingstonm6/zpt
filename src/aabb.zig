const i = @import("interval.zig");
const v = @import("vec3.zig");
const r = @import("ray.zig");

pub const AABB = struct {
    x: i.Interval = i.empty,
    y: i.Interval = i.empty,
    z: i.Interval = i.empty,

    fn padToMinimums(self: *AABB) void {
        const delta = 0.0001;
        if (self.x.size() < delta) self.x = self.x.expand(delta);
        if (self.y.size() < delta) self.y = self.y.expand(delta);
        if (self.z.size() < delta) self.z = self.z.expand(delta);
    }

    pub fn initIntervals(self: *AABB, int1: i.Interval, int2: i.Interval, int3: i.Interval) void {
        self.x = int1;
        self.y = int2;
        self.z = int3;
        self.padToMinimums();
    }

    pub fn initPoints(self: *AABB, a: *const v.point3, b: *const v.point3) void {
        self.x = if (a.x <= b.x) i.Interval{ .min = a.x, .max = b.x } else i.Interval{ .min = b.x, .max = a.x };
        self.y = if (a.y <= b.y) i.Interval{ .min = a.y, .max = b.y } else i.Interval{ .min = b.y, .max = a.y };
        self.z = if (a.z <= b.z) i.Interval{ .min = a.z, .max = b.z } else i.Interval{ .min = b.z, .max = a.z };
        self.padToMinimums();
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

    pub fn longestAxis(self: AABB) usize {
        if (self.x.size() > self.y.size()) {
            return if (self.x.size() > self.z.size()) 0 else 2;
        }
        return if (self.y.size() > self.z.size()) 1 else 2;
    }

    pub fn hit(self: AABB, ray: *const r.ray, ray_t: i.Interval) bool {
        var int = ray_t;
        for (0..3) |axis| {
            const ax = self.axisInterval(axis);
            const ad_inv: f64 = 1.0 / v.getByIndex(&ray.direction, axis);

            const t0 = (ax.min - v.getByIndex(&ray.origin, axis)) * ad_inv;
            const t1 = (ax.max - v.getByIndex(&ray.origin, axis)) * ad_inv;

            if (t0 < t1) {
                if (t0 > int.min) int.min = t0;
                if (t1 < int.max) int.max = t1;
            } else {
                if (t1 > int.min) int.min = t1;
                if (t0 < int.max) int.max = t0;
            }

            if (int.max <= int.min) {
                return false;
            }
        }
        return true;
    }

    pub fn addOffset(self: *AABB, offset: *const v.vec3) AABB {
        var result = AABB{};
        result.initIntervals(self.x.addOffset(offset.x), self.y.addOffset(offset.y), self.z.addOffset(offset.z));

        return result;
    }
};

pub const empty = AABB{ .x = i.empty, .y = i.empty, .z = i.empty };

test "intersection 1" {
    const std = @import("std");

    var box = AABB{};
    const point1 = v.point3{ .x = 1, .y = 1, .z = 1 };
    const point2 = v.point3{ .x = 4, .y = 4, .z = 4 };

    box.initPoints(&point1, &point2);
    std.log.debug("box:{any}", .{box});

    const origin = v.point3{ .x = 0, .y = 0, .z = 0 };
    const direction1 = v.vec3{ .x = 1, .y = 1, .z = 1 };
    const direction2 = v.vec3{ .x = -1, .y = -1, .z = -1 };

    const ray1 = r.ray{ .origin = origin, .direction = direction1 };
    const ray2 = r.ray{ .origin = origin, .direction = direction2 };

    var int = i.Interval{ .min = 0.001, .max = std.math.inf(f64) };
    const p_int: *i.Interval = &int;

    try std.testing.expectEqual(true, box.hit(&ray1, p_int));

    int = i.Interval{ .min = 0.001, .max = std.math.inf(f64) };
    try std.testing.expectEqual(false, box.hit(&ray2, p_int));
}

test "building aabb" {
    const std = @import("std");

    var box = AABB{};

    var box1 = AABB{};
    const point1 = v.point3{ .x = 0, .y = 0, .z = 0 };
    const point2 = v.point3{ .x = 1, .y = 1, .z = 1 };

    var box2 = AABB{};
    const point3 = v.point3{ .x = -1, .y = 1, .z = 1 };

    box1.initPoints(&point1, &point2);
    box2.initPoints(&point1, &point3);

    box.initBoxes(&box1, &box2);

    const int1 = i.Interval{ .min = -1, .max = 1 };
    const int2 = i.Interval{ .min = 0, .max = 1 };
    try std.testing.expectEqual(int1.min, box.x.min);
    try std.testing.expectEqual(int1.max, box.x.max);
    try std.testing.expectEqual(int2.min, box.y.min);
    try std.testing.expectEqual(int2.max, box.y.max);
    try std.testing.expectEqual(int2.min, box.z.min);
    try std.testing.expectEqual(int2.max, box.z.max);
}
