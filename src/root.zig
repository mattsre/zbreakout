//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub fn min(f1: f32, f2: f32) f32 {
    if (f1 < f2) {
        return f1;
    }

    return f2;
}

test "min helper validation" {
    try testing.expect(min(3.0, 7.0) == 3.0);
    try testing.expect(min(12.0, 10.0) == 10.0);
    try testing.expect(min(-50.0, 50.0) == -50);
    try testing.expect(min(-50.0, 0) == -50);
}
