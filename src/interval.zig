const std = @import("std");
const infinity = std.math.inf(f64);

pub const Interval = struct {
    min: f64 = infinity,
    max: f64 = -infinity,

    pub fn size(self: Interval) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, x: f64) bool {
        return self.min <= x and x <= self.max;
    }

    pub fn surrounds(self: Interval, x: f64) bool {
        return self.min < x and x < self.max;
    }

    pub fn clamp(self: Interval, x: f64) f64 {
        if (x < self.min) return self.min;
        if (x > self.max) return self.max;
        return x;
    }

    pub fn expand(self: Interval, delta: f64) Interval {
        const padding = delta / 2;
        return Interval{
            .min = self.min - padding,
            .max = self.max + padding,
        };
    }

    pub fn addOffset(self: Interval, offset: f64) Interval {
        return Interval{
            .min = self.min + offset,
            .max = self.max + offset,
        };
    }
};

pub fn fromIntervals(a: *const Interval, b: *const Interval) Interval {
    const min = if (a.min <= b.min) a.min else b.min;
    const max = if (a.max >= b.max) a.max else b.max;
    return Interval{ .min = min, .max = max };
}

pub const empty = Interval{
    .min = infinity,
    .max = -infinity,
};

pub const universe = Interval{
    .min = -infinity,
    .max = infinity,
};

test "fromIntervals" {
    const min1: f64 = -1.1101493574687844e1;
    const min2: f64 = -1.112247435406511e1;
    const max1: f64 = -1.0701493574687845e1;
    const max2: f64 = -1.0722474354065112e1;

    const int1 = Interval{ .min = min1, .max = max1 };
    const int2 = Interval{ .min = min2, .max = max2 };

    const int3 = fromIntervals(&int1, &int2);

    try std.testing.expectEqual(min2, int3.min);
    try std.testing.expectEqual(max1, int3.max);
}
