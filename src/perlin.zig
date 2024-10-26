const std = @import("std");
const util = @import("util.zig");
const vec = @import("vec3.zig");

fn trilinearInterpret(c: [2][2][2]f64, u: f64, v: f64, w: f64) f64 {
    var accum: f64 = 0.0;
    for (0..2) |i| {
        for (0..2) |j| {
            for (0..2) |k| {
                const f_i = @as(f64, @floatFromInt(i));
                const f_j = @as(f64, @floatFromInt(j));
                const f_k = @as(f64, @floatFromInt(k));
                accum += (f_i * u + (1 - f_i) * (1 - u)) * (f_j * v + (1 - f_j) * (1 - v)) * (f_k * w + (1 - f_k) * (1 - w)) * c[i][j][k];
            }
        }
    }

    return accum;
}

fn perlinInterpret(c: [2][2][2]vec.vec3, u: f64, v: f64, w: f64) f64 {
    const uu = u * u * (3 - 2 * u);
    const vv = v * v * (3 - 2 * v);
    const ww = w * w * (3 - 2 * w);

    var accum: f64 = 0.0;

    for (0..2) |i| {
        for (0..2) |j| {
            for (0..2) |k| {
                const f_i: f64 = @floatFromInt(i);
                const f_j: f64 = @floatFromInt(j);
                const f_k: f64 = @floatFromInt(k);

                const weight = vec.vec3{ .x = u - f_i, .y = v - f_j, .z = w - f_k };
                accum += (f_i * uu + (1 - f_i) * (1 - uu)) * (f_j * vv + (1 - f_j) * (1 - vv)) * (f_k * ww + (1 - f_k) * (1 - ww)) * vec.dotProduct(&c[i][j][k], &weight);
            }
        }
    }

    return accum;
}

pub const Perlin = struct {
    point_count: usize = 256,
    rand: []vec.vec3 = undefined,
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
        self.rand = try allocator.alloc(vec.vec3, self.point_count);
        self.perm_x = try allocator.alloc(usize, self.point_count);
        self.perm_y = try allocator.alloc(usize, self.point_count);
        self.perm_z = try allocator.alloc(usize, self.point_count);

        for (0..self.point_count) |i| {
            self.rand[i] = vec.unit(&try vec.randomRange(-1, 1));
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

    pub fn noise(self: Perlin, p: *const vec.point3) !f64 {
        const u = p.x - @floor(p.x);
        const v = p.y - @floor(p.y);
        const w = p.z - @floor(p.z);

        const i = @as(isize, @intFromFloat(@floor(p.x)));
        const j = @as(isize, @intFromFloat(@floor(p.y)));
        const k = @as(isize, @intFromFloat(@floor(p.z)));

        var c: [2][2][2]vec.vec3 = undefined;

        for (0..2) |di| {
            for (0..2) |dj| {
                for (0..2) |dk| {
                    const i_di: isize = @as(isize, @intCast(di));
                    const i_dj: isize = @as(isize, @intCast(dj));
                    const i_dk: isize = @as(isize, @intCast(dk));

                    const p_count = @as(isize, @intCast(self.point_count));

                    const index: usize = @intCast((self.perm_x[@as(usize, @intCast(try std.math.mod(isize, i + i_di, p_count)))] ^
                        self.perm_y[@as(usize, @intCast(try std.math.mod(isize, j + i_dj, p_count)))] ^
                        self.perm_z[@as(usize, @intCast(try std.math.mod(isize, k + i_dk, p_count)))]));

                    c[di][dj][dk] = self.rand[index];
                }
            }
        }

        return perlinInterpret(c, u, v, w);
    }
};
