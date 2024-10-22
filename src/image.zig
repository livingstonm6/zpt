const zstbi = @import("zstbi");
const std = @import("std");

fn clamp(x: usize, low: usize, high: usize) usize {
    if (x < low) return low;
    if (x < high) return x;
    return high - 1;
}

fn f64ToU8(value: f32) u8 {
    if (value <= 0.0) return 0;
    if (1.0 < value) return 255;
    return @as(u8, @intFromFloat(256.0 * value));
}

pub const Image = struct {
    bytes_per_pixel: u32 = 3,
    float_data: ?[*]f32 = null,
    byte_data: []u8 = undefined,
    byte_length: usize = 0,
    image_width: u8 = 0,
    image_height: u8 = 0,
    bytes_per_scanline: u32 = 0,
    filename: [:0]const u8 = undefined,
    allocator: std.mem.Allocator = undefined,
    default_data: []u8 = undefined,
    image: zstbi.Image = undefined,
    loaded: bool = false,

    pub fn init(self: *Image, filename: [:0]const u8, allocator: std.mem.Allocator) !void {
        self.filename = filename;
        self.allocator = allocator;

        zstbi.init(self.allocator);
        self.default_data = try self.allocator.alloc(u8, 3);
        self.default_data[0] = 255;
        self.default_data[1] = 0;
        self.default_data[2] = 255;
        try self.load();
        if (!self.loaded) {
            std.log.debug("Error: File not found: {s}", .{filename});
            std.process.exit(1);
        }
    }

    pub fn deinit(self: *Image) void {
        self.image.deinit();
        zstbi.deinit();
        self.allocator.free(self.byte_data);
        self.allocator.free(self.default_data);
    }

    pub fn load(self: *Image) !void {
        self.image = try zstbi.Image.loadFromFile(self.filename, self.bytes_per_pixel);
        self.bytes_per_scanline = self.image.width * self.bytes_per_pixel;
        self.loaded = true;
    }

    pub fn pixelData(self: Image, x: usize, y: usize) []u8 {
        const clamp_x = clamp(x, 0, self.image.width);
        const clamp_y = clamp(y, 0, self.image.height);

        const index = clamp_y * self.bytes_per_scanline + clamp_x * self.bytes_per_pixel;

        if (index + 3 >= self.image.data.len) {
            return self.default_data;
        }

        return self.image.data[index .. index + 3];
    }
};
