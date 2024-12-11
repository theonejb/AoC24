const std = @import("std");
const utils = @import("./utils.zig");
const combinations = @import("./combinations.zig");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const map = try parseInput(allocator);
    defer map.deinit();

    const map_str = try map.to_str();
    std.debug.print("{s}\n", .{map_str});
    allocator.free(map_str);

    // Part 1
    const pairs = try map.antenna_pairs();
    defer allocator.free(pairs);

    var seen_antinodes = std.AutoHashMap(HashablePosition, bool).init(allocator);
    var in_map_bounds: u32 = 0;
    for (pairs) |pair| {
        const antinodes = calculate_antinodes(pair);
        const p1 = antinodes[0];
        const hp1 = p1.hashable();
        const p2 = antinodes[1];
        const hp2 = p2.hashable();

        if (map.valid_antinode_position(p1) and !seen_antinodes.contains(hp1)) {
            in_map_bounds += 1;
            try seen_antinodes.put(hp1, true);
        }
        if (map.valid_antinode_position(p2) and !seen_antinodes.contains(hp2)) {
            in_map_bounds += 1;
            try seen_antinodes.put(hp2, true);
        }
    }

    std.debug.print("{d} antinodes in map.\n", .{in_map_bounds});
}

fn calculate_antinodes(pair: AntennaPair) [2]Position {
    const p1 = pair.a;
    const p1x = p1.position.x;
    const p1y = p1.position.y;

    const p2 = pair.b;
    const p2x = p2.position.x;
    const p2y = p2.position.y;

    const dy = p2y - p2y;
    const dx = p2x - p1x;

    const a1x = p1x - dx;
    const a1y = p1y - dy;

    const a2x = p2x + dx;
    const a2y = p2y + dy;

    return .{ Position{
        .x = a1x,
        .y = a1y,
    }, Position{
        .x = a2x,
        .y = a2y,
    } };
}

const HashablePosition = struct { i64, i64 };
const Position = struct {
    x: f64,
    y: f64,

    fn eq(self: Position, other: Position) bool {
        return (self.x == other.x and self.y == other.y);
    }

    fn hashable(self: Position) HashablePosition {
        return .{ @intFromFloat(self.x), @intFromFloat(self.y) };
    }
};
const Antenna = struct {
    frequency: u8,
    position: Position,
};
const AntennaPair = struct {
    frequency: u8,
    a: Antenna,
    b: Antenna,
};
const Map = struct {
    width: usize,
    height: usize,
    antennas: []Antenna,

    allocator: Allocator,

    fn deinit(self: Map) void {
        self.allocator.free(self.antennas);
    }

    fn to_str(self: Map) ![]u8 {
        // Total length of string. Height - 1 accounts for the new line characters
        const map_str_len = self.width * self.height + (self.height - 1);
        var map_str = try self.allocator.alloc(u8, map_str_len);
        @memset(map_str, '.');

        for (self.antennas) |antenna| {
            // Rows + new lines + Cols
            const i = antenna.position.y * @as(f64, @floatFromInt(self.width)) + antenna.position.y + antenna.position.x;
            map_str[@intFromFloat(i)] = antenna.frequency;
        }

        for (0..self.height - 1) |i| {
            const break_index = i * self.width + i + self.width;
            map_str[break_index] = '\n';
        }

        return map_str;
    }

    fn position_in_map(self: Map, position: Position) bool {
        return ((position.x >= 0 and position.x < @as(f64, @floatFromInt(self.width))) and
            (position.y >= 0 and position.y < @as(f64, @floatFromInt(self.height))));
    }

    fn overlaps_another_antena(self: Map, position: Position) bool {
        for (self.antennas) |antenna| {
            if (position.eq(antenna.position)) return true;
        }

        return false;
    }

    fn valid_antinode_position(self: Map, antinode_position: Position) bool {
        return self.position_in_map(antinode_position) and !self.overlaps_another_antena(antinode_position);
    }

    fn antenna_by_frequency(self: Map) !std.AutoHashMap(u8, []Antenna) {
        var result = std.AutoHashMap(u8, []Antenna).init(self.allocator);

        const frequencies_list = try self.frequencies();
        defer self.allocator.free(frequencies_list);

        for (frequencies_list) |frequency| {
            var antennas = std.ArrayList(Antenna).init(self.allocator);

            for (self.antennas) |antenna| {
                if (antenna.frequency == frequency) {
                    try antennas.append(antenna);
                }
            }

            try result.put(frequency, try antennas.toOwnedSlice());
            antennas.deinit();
        }

        return result;
    }

    fn frequencies(self: Map) ![]u8 {
        var freqs = std.ArrayList(u8).init(self.allocator);
        defer freqs.deinit();

        outer: for (self.antennas) |antenna| {
            const freq = antenna.frequency;

            for (freqs.items) |seen_freq| {
                if (seen_freq == freq) continue :outer;
            }

            try freqs.append(freq);
        }

        return try freqs.toOwnedSlice();
    }

    fn antenna_pairs(self: Map) ![]AntennaPair {
        var pairs = std.ArrayList(AntennaPair).init(self.allocator);
        defer pairs.deinit();

        var antenna_by_frequency_local = try self.antenna_by_frequency();
        defer {
            var it = antenna_by_frequency_local.valueIterator();
            while (it.next()) |antennas| {
                self.allocator.free(antennas.*);
            }
            antenna_by_frequency_local.deinit();
        }

        var it = antenna_by_frequency_local.iterator();
        while (it.next()) |entry| {
            const freq = entry.key_ptr.*;
            const antennas = entry.value_ptr.*;

            var combinations_generator = try combinations.Generator(Antenna).init(self.allocator, 2, antennas);
            defer combinations_generator.deinit();

            while (try combinations_generator.next()) |combination| {
                try pairs.append(.{
                    .a = combination[0],
                    .b = combination[1],
                    .frequency = freq,
                });

                self.allocator.free(combination);
            }
        }

        return try pairs.toOwnedSlice();
    }
};

fn parseInput(allocator: Allocator) !Map {
    const lines = try utils.fileToLines(allocator, "./inputs/day8.txt");
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var antenna = std.ArrayList(Antenna).init(allocator);
    defer antenna.deinit();

    for (lines.items, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == '.') continue;

            try antenna.append(Antenna{
                .frequency = char,
                .position = .{
                    .x = @floatFromInt(col),
                    .y = @floatFromInt(row),
                },
            });
        }
    }

    return Map{
        .width = lines.items[0].len,
        .height = lines.items.len,
        .antennas = try antenna.toOwnedSlice(),
        .allocator = allocator,
    };
}
