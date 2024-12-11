const utils = @import("utils.zig");
const std = @import("std");

pub fn main() !void {
    const lines = try utils.fileToLines("inputs/day4.txt");
    defer lines.deinit();

    std.debug.print("Part 1: {d}\n", .{try countXmasStrings(lines.items)});
    std.debug.print("Part 2: {d}\n", .{try solvePart2(lines.items)});
}

const Point = struct {
    col: i32,
    row: i32,

    fn moveTo(self: Point, move: Move) Point {
        return .{ .col = self.col + move.cols, .row = self.row + move.rows };
    }
};

const Move = struct {
    cols: i8 = 0,
    rows: i8 = 0,
};
const Directions = [_]Move{
    Move{ .cols = 1, .rows = 0 }, // Right
    Move{ .cols = -1, .rows = 0 }, // Left
    Move{ .cols = 0, .rows = 1 }, // Down
    Move{ .cols = 0, .rows = -1 }, // Up
    Move{ .cols = 1, .rows = 1 }, // Down-Right
    Move{ .cols = -1, .rows = -1 }, // Up-Left
    Move{ .cols = 1, .rows = -1 }, // Up-Right
    Move{ .cols = -1, .rows = 1 }, // Down-Left
};

fn countXmasStrings(lines: [][]const u8) !u32 {
    var countOfXmasStrings: u32 = 0;

    const xCharIndexes = findXCharIndexes(lines);
    for (xCharIndexes) |index| {
        for (Directions) |direction| {
            const neighbourPointsToCheck = getPointsToCheckForMatchingChars(index, direction);
            if (eqXmas(lines, neighbourPointsToCheck)) {
                countOfXmasStrings += 1;
            }
        }
    }

    return countOfXmasStrings;
}

fn eqXmas(lines: [][]const u8, points: []Point) bool {
    var counter = std.AutoHashMap(u8, u8).init(std.heap.page_allocator);
    defer counter.deinit();

    const chars = "XMAS";
    var cPointer: u8 = 0;

    for (points) |point| {
        if (!isValidPoint(lines, point)) {
            return false;
        }

        if (lines[@intCast(point.row)][@intCast(point.col)] != chars[cPointer]) {
            return false;
        }

        cPointer += 1;
    }

    return true;
}

fn isValidPoint(lines: [][]const u8, point: Point) bool {
    return ((point.row >= 0 and point.row < lines.len) and
        (point.col >= 0 and point.col < lines[0].len));
}

fn getPointsToCheckForMatchingChars(start: Point, direction: Move) []Point {
    var points = std.ArrayList(Point).init(std.heap.page_allocator);

    var currentPoint = start;
    for (0..4) |_| {
        points.append(currentPoint) catch unreachable;
        currentPoint.col += direction.cols;
        currentPoint.row += direction.rows;
    }

    return points.items;
}

fn findCharIndexes(lines: [][]const u8, char: u8) []Point {
    var indexes = std.ArrayList(Point).init(std.heap.page_allocator);

    for (0..lines.len) |row| {
        for (0..lines[0].len) |col| {
            if (lines[row][col] == char) {
                indexes.append(Point{ .col = @truncate(@as(i128, col)), .row = @truncate(@as(i128, row)) }) catch unreachable;
            }
        }
    }
    return indexes.items;
}

fn findXCharIndexes(lines: [][]const u8) []Point {
    return findCharIndexes(lines, 'X');
}

const CrossPoints = [2][2]Move{
    [2]Move{ Move{ .cols = -1, .rows = -1 }, Move{ .cols = 1, .rows = 1 } },
    [2]Move{ Move{ .cols = 1, .rows = -1 }, Move{ .cols = -1, .rows = 1 } },
};

fn getPointsToCheckForCross(startingPoint: Point) [][]Point {
    var pointsArray = std.ArrayList([]Point).init(std.heap.page_allocator);

    for (CrossPoints) |cross| {
        const d1Move = cross[0];
        const d2Move = cross[1];

        var points = std.ArrayList(Point).init(std.heap.page_allocator);
        points.append(startingPoint.moveTo(d1Move)) catch unreachable;
        points.append(startingPoint) catch unreachable;
        points.append(startingPoint.moveTo(d2Move)) catch unreachable;

        pointsArray.append(points.items) catch unreachable;
    }

    return pointsArray.items;
}

fn findACharIndexes(lines: [][]const u8) []Point {
    return findCharIndexes(lines, 'A');
}

fn eqCrossMas(lines: [][]const u8, points: []Point) bool {
    if (points.len != 3) return false;

    // We alredy know there is 1 A since that's the middle of our point
    var mCount: u8 = 0;
    var sCount: u8 = 0;

    for (points) |point| {
        if (!isValidPoint(lines, point)) return false;

        switch (lines[@intCast(point.row)][@intCast(point.col)]) {
            'M' => mCount += 1,
            'S' => sCount += 1,
            'A' => {}, // Do nothing for 'A' as it's the middle point
            else => return false, // If any other character is found, return false
        }
    }

    return (mCount == 1 and sCount == 1);
}

fn solvePart2(lines: [][]const u8) !u32 {
    var count: u32 = 0;

    const midPoints = findACharIndexes(lines);
    for (midPoints) |point| {
        const pointsToCheck = getPointsToCheckForCross(point);
        var match = true;
        for (pointsToCheck) |diagonalPoints| {
            if (!eqCrossMas(lines, diagonalPoints)) {
                match = false;
            }
        }

        if (match) count += 1;
    }

    return count;
}
