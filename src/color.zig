const std = @import("std");
const v = @import("vec3.zig");
const interval = @import("interval.zig");

pub const color = v.vec3;

const intensity = interval.Interval{ .min = 0.000, .max = 0.999 };

fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0) {
        return std.math.sqrt(linear_component);
    }
    return 0.0;
}

pub fn writeColor(w: anytype, pixel_color: *const color) !void {
    const r = linearToGamma(pixel_color.x);
    const g = linearToGamma(pixel_color.y);
    const b = linearToGamma(pixel_color.z);

    const ir: u16 = @as(u16, @intFromFloat(256 * intensity.clamp(r)));
    const ig: u16 = @as(u16, @intFromFloat(256 * intensity.clamp(g)));
    const ib: u16 = @as(u16, @intFromFloat(256 * intensity.clamp(b)));

    try w.print("{} {} {}\n", .{ ir, ig, ib });
}
