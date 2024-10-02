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
