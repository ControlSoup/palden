const std = @import("std");

// =================================================
// Needed Memory
// =================================================

// {e} for floats, {d} for ints
// Max i32: 2147483647
// Min i32: -2147483648
// Max u64: 18446744073709551615
// Min u64: 0
// Max f32: 3.4028235e38
// Min f32: -1.1754944e-38

pub var pre_allocated_data: [3e5]u8 = undefined;
