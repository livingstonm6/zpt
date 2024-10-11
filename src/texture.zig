const c = @import("color.zig");
const vec = @import("vec3.zig");
const std = @import("std");

pub const SolidColor = struct {
    albedo: c.color = undefined,

    pub fn initRGB(self: *SolidColor, r: f64, g: f64, b: f64) void {
        self.albedo = c.color{ .x = r, .y = g, .z = b };
    }

    pub fn value(self: SolidColor, u: f64, v: f64, p: *const vec.point3) c.color {
        _ = .{ u, v, p };
        return self.albedo;
    }
};

pub const CheckerTexture = struct {
    inv_scale: f64 = undefined,
    even: *const Texture = undefined,
    odd: *const Texture = undefined,

    pub fn init(self: *CheckerTexture, scale: f64, even: *const Texture, odd: *const Texture) void {
        self.inv_scale = 1.0 / scale;
        self.even = even;
        self.odd = odd;
    }

    pub fn initColors(self: *CheckerTexture, scale: f64, color1: *const c.color, color2: *const c.color) void {
        var t1 = Texture{ .solidColor = SolidColor{ .albedo = color1.* } };
        var t2 = Texture{ .solidColor = SolidColor{ .albedo = color2.* } };
        self.init(
            scale,
            &t1,
            &t2,
        );
    }

    pub fn value(self: CheckerTexture, u: f64, v: f64, p: *const vec.point3) c.color {
        const xInt = @as(i32, @intFromFloat(@floor(self.inv_scale * p.x)));
        const yInt = @as(i32, @intFromFloat(@floor(self.inv_scale * p.y)));
        const zInt = @as(i32, @intFromFloat(@floor(self.inv_scale * p.z)));

        const isEven = @rem(xInt + yInt + zInt, 2) == 0;

        return if (isEven) self.even.solidColor.value(u, v, p) else self.odd.solidColor.value(u, v, p); // c.color{ .x = 1, .y = 1, .z = 1 }; //self.odd.*.value(u, v, p);
    }
};

pub const Texture = union(enum) {
    solidColor: SolidColor,
    checkerTexture: CheckerTexture,

    pub fn value(self: Texture, u: f64, v: f64, p: *const vec.point3) c.color {
        switch (self) {
            inline else => |case| return case.value(u, v, p),
        }
    }
};
