const std = @import("std");
const v = @import("vec3.zig");
pub const color = v.vec3;

pub fn writeColor(w: anytype, pixel_color: *const color) !void {
    const r = pixel_color.x;
    const g = pixel_color.y;
    const b = pixel_color.z;

    const ir: u16 = @as(u16, @intFromFloat(255.999 * r));
    const ig: u16 = @as(u16, @intFromFloat(255.999 * g));
    const ib: u16 = @as(u16, @intFromFloat(255.999 * b));

    try w.print("{} {} {}\n", .{ ir, ig, ib });
}