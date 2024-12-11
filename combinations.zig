const std = @import("std");
const testing = std.testing;

/// A generator for combinations of items without replacement.
///
/// Given a slice of items of type T and a number of slots n, generates all possible combinations
/// of n items from the input slice.
///
/// The generator clones the choices slice and will free it when deinit() is called.
/// Each call to next() returns an owned slice that must be freed by the caller.
///
/// Example:
/// ```
/// // Generates: 12, 13, 23
/// var gen = try Generator(u8).init(allocator, 2, &[_]u8{1,2,3});
/// defer gen.deinit();
///
/// while (try gen.next()) |combination| {
///     defer allocator.free(combination);
///     // use combination...
/// }
/// ```
pub fn Generator(comptime T: type) type {
    return struct {
        choices: []T,
        slots: u32,
        allocator: std.mem.Allocator,

        current_combination: u32 = 0,

        const Self = Generator(T);

        pub fn init(allocator: std.mem.Allocator, n: u32, choices: []const T) !Self {
            const owned_choices = try allocator.alloc(T, choices.len);
            @memcpy(owned_choices, choices);

            return .{
                .choices = owned_choices,
                .slots = n,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.choices);
        }

        pub fn next(self: *Self) !?[]const T {
            while (self.count_of_on_bits(self.current_combination) != self.slots) {
                self.current_combination += 1;
            }

            if (self.current_combination >= std.math.pow(u32, 2, @intCast(self.choices.len))) {
                return null;
            }

            var choices = std.ArrayList(T).init(self.allocator);
            defer choices.deinit();

            var i: u5 = 0;
            for (self.choices) |choice| {
                if ((self.current_combination & (@as(u32, 1) << i)) != 0) {
                    try choices.append(choice);
                }
                i += 1;
            }

            self.current_combination += 1;
            return try choices.toOwnedSlice();
        }

        fn count_of_on_bits(_: Self, n: u32) u32 {
            var count: u8 = 0;
            var num = n;
            while (num > 0) {
                count += 1;
                num = num & (num - 1);
            }

            return count;
        }
    };
}

test "initialization" {
    const allocator = std.testing.allocator;

    const choices = [5]u8{ 1, 2, 3, 4, 5 };
    const generator = try Generator(u8).init(allocator, 2, &choices);
    defer generator.deinit();

    try testing.expectEqual(2, generator.slots);

    try testing.expectEqual(5, generator.choices.len);
    try testing.expectEqualSlices(u8, &choices, generator.choices);
}

test "next() - first choice" {
    const allocator = std.testing.allocator;

    const choices = [_]u8{ 'A', 'B', 'C', 'D' };
    var generator = try Generator(u8).init(allocator, 2, &choices);
    defer generator.deinit();

    const first_choice = (try generator.next()).?;
    defer allocator.free(first_choice);

    try testing.expectEqualSlices(u8, &[2]u8{ 'A', 'B' }, first_choice);
}

test "next() - iterate" {
    const allocator = std.testing.allocator;

    const choices = [_]u8{ 'A', 'B', 'C', 'D' };
    var generator = try Generator(u8).init(allocator, 2, &choices);
    defer generator.deinit();

    const expected_choices = [_][]const u8{ "AB", "AC", "AD", "BC", "BD", "CD" };

    var seen_choices = std.StringHashMap(bool).init(allocator);
    while (try generator.next()) |choice| {
        try seen_choices.put(choice, true);
    }

    for (expected_choices) |expected_choice| {
        try testing.expect(seen_choices.contains(expected_choice));
    }

    var it = seen_choices.keyIterator();
    while (it.next()) |k| {
        allocator.free(k.*);
    }

    seen_choices.deinit();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const choices = [_]u8{ 'A', 'B', 'C', 'D' };
    var generator = try Generator(u8).init(allocator, 2, &choices);
    defer generator.deinit();

    while (try generator.next()) |choice| {
        std.debug.print("{s}\n", .{choice});
        allocator.free(choice);
    }
}
