const std = @import("std");
const a = @import("aabb.zig");
const h = @import("hittable.zig");
const i = @import("interval.zig");
const r = @import("ray.zig");
const util = @import("util.zig");

fn boxCompare(h1: h.Hittable, h2: h.Hittable, axis: u8) bool {
    const h1_axis_interval = h1.boundingBox().axisInterval(axis);
    const h2_axis_interval = h2.boundingBox().axisInterval(axis);
    return h1_axis_interval.min < h2_axis_interval.min;
}
fn boxCompareX(_: void, h1: h.Hittable, h2: h.Hittable) bool {
    return boxCompare(h1, h2, 0);
}
fn boxCompareY(_: void, h1: h.Hittable, h2: h.Hittable) bool {
    return boxCompare(h1, h2, 1);
}
fn boxCompareZ(_: void, h1: h.Hittable, h2: h.Hittable) bool {
    return boxCompare(h1, h2, 2);
}

pub const BVHNode = struct {
    left: *h.Hittable = undefined,
    right: *h.Hittable = undefined,
    box: a.AABB = undefined,

    pub fn initBoundingBox(self: *const BVHNode) void {
        _ = self;
    }

    pub fn initTree(self: *BVHNode, list: *h.HittableList, allocator: std.mem.Allocator) !void {
        try self.init(&list.objects, 0, list.getLen(), allocator);
    }

    fn init(self: *BVHNode, list: *std.ArrayList(h.Hittable), start: usize, end: usize, allocator: std.mem.Allocator) !void {
        const object_span = end - start;

        if (object_span == 1) {
            self.left = &list.items[start];
            self.right = &list.items[start];
        } else if (object_span == 2) {
            self.left = &list.items[start];
            self.right = &list.items[start + 1];
        } else {
            const axis = try util.randomU8Range(0, 2);
            switch (axis) {
                0 => std.sort.block(h.Hittable, list.items[start..end], {}, boxCompareX),
                1 => std.sort.block(h.Hittable, list.items[start..end], {}, boxCompareY),
                else => std.sort.block(h.Hittable, list.items[start..end], {}, boxCompareZ),
            }
            const midpoint = start + (object_span / 2);
            self.left = try allocator.create(h.Hittable);
            self.left.* = h.Hittable{ .bvh = BVHNode{} };
            try self.left.bvh.init(list, start, midpoint, allocator);

            self.right = try allocator.create(h.Hittable);
            self.right.* = h.Hittable{ .bvh = BVHNode{} };
            try self.right.bvh.init(list, midpoint, end, allocator);
        }

        self.box = a.AABB{};
        self.box.initBoxes(&self.left.boundingBox(), &self.right.boundingBox());
    }

    pub fn hit(self: BVHNode, ray: *const r.ray, ray_t: i.Interval, record: *h.HitRecord) bool {
        if (!self.box.hit(ray, ray_t)) {
            return false;
        }

        const hit_left = self.left.hit(ray, ray_t, record);
        const int = i.Interval{
            .min = ray_t.min,
            .max = if (hit_left) record.t else ray_t.max,
        };

        const hit_right = self.right.hit(ray, int, record);

        return hit_left or hit_right;
    }

    pub fn boundingBox(self: BVHNode) a.AABB {
        return self.box;
    }
};
