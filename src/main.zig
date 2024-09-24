const std = @import("std");
const c = @import("color.zig");

pub fn main() !void {
    const image_width: u16 = 256;
    const image_height: u16 = 256;

    // render
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        std.log.info("Scanline {} of {}.", .{ j, image_height });
        for (0..image_width) |i| {
            const pixel_color = c.color{
                .x = @as(f64, @floatFromInt(i)) / (image_width - 1),
                .y = @as(f64, @floatFromInt(j)) / (image_height - 1),
                .z = 0.0,
            };

            try c.writeColor(stdout, &pixel_color);
        }
    }

    std.log.info("Complete!", .{});

    // write to stdout, pipe into file

    try bw.flush();
}

// pub fn main() !void {
//     // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
//     std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

//     // stdout is for the actual output of your application, for example if you
//     // are implementing gzip, then only the compressed bytes should be sent to
//     // stdout, not any debugging messages.
//     const stdout_file = std.io.getStdOut().writer();
//     var bw = std.io.bufferedWriter(stdout_file);
//     const stdout = bw.writer();

//     try stdout.print("Run `zig build test` to run the tests.\n", .{});

//     try bw.flush(); // don't forget to flush!
// }

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
