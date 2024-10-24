const c = @import("color.zig");
const vec = @import("vec3.zig");
const std = @import("std");
const i = @import("image.zig");
const int = @import("interval.zig");
const perlin = @import("perlin.zig");

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

pub const ImageTexture = struct {
    fileName: [:0]const u8,
    image: i.Image = undefined,

    pub fn init(self: *ImageTexture, allocator: std.mem.Allocator) !void {
        self.image = i.Image{};
        try self.image.init(self.fileName, allocator);
    }

    pub fn deinit(self: *ImageTexture) void {
        self.image.deinit();
    }

    pub fn value(self: ImageTexture, u: f64, v: f64, p: *const vec.point3) c.color {
        _ = p;
        if (self.image.loaded == false) return c.color{ .x = 0, .y = 1, .z = 1 };

        const int1 = int.Interval{ .min = 0, .max = 1 };
        const clamp_u = int1.clamp(u);
        const clamp_v = 1.0 - int1.clamp(v);

        const float_width = @as(f64, @floatFromInt(self.image.image.width));
        const float_height = @as(f64, @floatFromInt(self.image.image.height));

        const i_ = @as(usize, @intFromFloat(clamp_u * float_width));
        const j = @as(usize, @intFromFloat(clamp_v * float_height));

        const pixel = self.image.pixelData(i_, j);

        const colour_scale = 1.0 / 255.0;
        return c.color{
            .x = colour_scale * @as(f64, @floatFromInt(pixel[0])),
            .y = colour_scale * @as(f64, @floatFromInt(pixel[1])),
            .z = colour_scale * @as(f64, @floatFromInt(pixel[2])),
        };
    }
};

pub const NoiseTexture = struct {
    noise: perlin.Perlin = perlin.Perlin{},

    pub fn init(self: *NoiseTexture, allocator: std.mem.Allocator) !void {
        try self.noise.init(allocator);
    }

    pub fn deinit(self: *NoiseTexture) void {
        self.noise.deinit();
    }

    pub fn value(self: NoiseTexture, u: f64, v: f64, p: *const vec.point3) c.color {
        _ = .{ u, v };
        return vec.multiply(&c.color{ .x = 1, .y = 1, .z = 1 }, self.noise.noise(p));
    }
};

pub const Texture = union(enum) {
    solidColor: SolidColor,
    checkerTexture: CheckerTexture,
    imageTexture: ImageTexture,
    noiseTexture: NoiseTexture,

    pub fn value(self: Texture, u: f64, v: f64, p: *const vec.point3) c.color {
        switch (self) {
            inline else => |case| return case.value(u, v, p),
        }
    }
};
