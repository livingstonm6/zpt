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
};

pub const empty = Interval{
    .min = infinity,
    .max = -infinity,
};

pub const universe = Interval{
    .min = -infinity,
    .max = infinity,
};
