const std = @import("std");
const util = @import("util.zig");
const vec = @import("vec3.zig");

pub const Perlin = struct {
    point_count: usize = 256,
    rand: []f64 = undefined,
    perm_x: []usize = undefined,
    perm_y: []usize = undefined,
    perm_z: []usize = undefined,
    allocator: std.mem.Allocator = undefined,

    fn generatePerm(self: Perlin, perm: []usize) !void {
        for (0..self.point_count) |i| {
            perm[i] = i;
        }
        try self.permute(perm, self.point_count);
    }

    fn permute(self: Perlin, perm: []usize, n: usize) !void {
        _ = self;
        var i = n - 1;
        while (i > 0) {
            const target = try util.randomUsizeRange(0, i);
            const temp = perm[i];
            perm[i] = perm[target];
            perm[target] = temp;

            i -= 1;
        }
    }

    pub fn init(self: *Perlin, allocator: std.mem.Allocator) !void {
        self.rand = try allocator.alloc(f64, self.point_count);
        self.perm_x = try allocator.alloc(usize, self.point_count);
        self.perm_y = try allocator.alloc(usize, self.point_count);
        self.perm_z = try allocator.alloc(usize, self.point_count);

        for (0..self.point_count) |i| {
            self.rand[i] = try util.randomF64();
        }

        try self.generatePerm(self.perm_x);
        try self.generatePerm(self.perm_y);
        try self.generatePerm(self.perm_z);

        self.allocator = allocator;
    }

    pub fn deinit(self: *Perlin) void {
        self.allocator.free(self.rand);
        self.allocator.free(self.perm_x);
        self.allocator.free(self.perm_y);
        self.allocator.free(self.perm_z);
    }

    pub fn noise(self: Perlin, p: *const vec.point3) f64 {
        const i = @as(usize, @intFromFloat(4 * if (p.x > 0) p.x else -p.x)) & 255;
        const j = @as(usize, @intFromFloat(4 * if (p.y > 0) p.y else -p.y)) & 255;
        const k = @as(usize, @intFromFloat(4 * if (p.z > 0) p.z else -p.z)) & 255;

        return self.rand[self.perm_x[i] ^ self.perm_y[j] ^ self.perm_z[k]];
    }
};
