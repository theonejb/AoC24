const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    const lines = try utils.fileToLines("inputs/day6.txt");
    defer lines.deinit();

    const grid = try inputToGrid(lines.items);

    const visitedPositionsCount = try simulateAndCountUniquePositionsVisited(grid);
    std.debug.print("Guard visited {d} positions before existing.\n", .{visitedPositionsCount});

    const optionsToCauseLooping = try numberOfOptionsToCauseLooping(grid);
    std.debug.print("There are {d} obstruction placement options that can cause looping.\n", .{optionsToCauseLooping});
}

const Position = struct {
    x: i32,
    y: i32,

    fn eq(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Obstruction = struct {
    position: Position,
};

const Direction = enum {
    North,
    East,
    South,
    West,

    fn dx(self: Direction) i8 {
        return switch (self) {
            .North => 0,
            .East => 1,
            .South => 0,
            .West => -1,
        };
    }

    fn dy(self: Direction) i8 {
        return switch (self) {
            .North => -1,
            .East => 0,
            .South => 1,
            .West => 0,
        };
    }

    fn turnRight(self: Direction) Direction {
        return switch (self) {
            .North => .East,
            .East => .South,
            .South => .West,
            .West => .North,
        };
    }
};

const Guard = struct { position: Position, direction: Direction };

const Grid = struct {
    width: u32,
    height: u32,
    obstructions: []Obstruction,
    guard: Guard,

    fn hasObstruction(self: Grid, at: Position) bool {
        for (self.obstructions) |obstruction| {
            if (obstruction.position.x == at.x and obstruction.position.y == at.y) return true;
        }

        return false;
    }

    fn positionInBounds(self: Grid, at: Position) bool {
        return (at.x >= 0 and at.x < self.width and at.y >= 0 and at.y < self.height);
    }

    fn printGuardPosition(self: Grid) void {
        std.debug.print("Guard @ ({d},{d}) facing {s}\n", .{ self.guard.position.x, self.guard.position.y, @tagName(self.guard.direction) });
    }

    fn withObstructionAt(self: Grid, new_obstruction_position: Position) !Grid {
        var new_obstructions = std.ArrayList(Obstruction).init(std.heap.page_allocator);
        defer new_obstructions.deinit();

        for (self.obstructions) |obstruction| {
            try new_obstructions.append(obstruction);
        }
        try new_obstructions.append(Obstruction{ .position = new_obstruction_position });

        return Grid{ .width = self.width, .height = self.height, .obstructions = try new_obstructions.toOwnedSlice(), .guard = self.guard };
    }
};

fn inputToGrid(lines: [][]const u8) !Grid {
    var obstructions = std.ArrayList(Obstruction).init(std.heap.page_allocator);
    var guard: ?Guard = null;

    for (0..lines.len) |row| {
        for (0..lines[0].len) |col| {
            switch (lines[row][col]) {
                '#' => {
                    try obstructions.append(Obstruction{ .position = Position{ .x = @intCast(col), .y = @intCast(row) } });
                },
                '^' => {
                    guard = Guard{ .direction = .North, .position = Position{ .x = @intCast(col), .y = @intCast(row) } };
                },
                else => {},
            }
        }
    }

    if (guard) |g| {
        return Grid{ .width = @intCast(lines[0].len), .height = @intCast(lines.len), .obstructions = try obstructions.toOwnedSlice(), .guard = g };
    }
    return error.UnparsableInput;
}

fn simulateAndCountUniquePositionsVisited(grid: Grid) !u32 {
    const visitedPositions = try getVisitedPositions(grid);
    return visitedPositions.count();
}

fn getVisitedPositions(grid: Grid) !std.AutoHashMap(Position, u32) {
    var guard = grid.guard;
    var visitedPositions = std.AutoHashMap(Position, u32).init(std.heap.page_allocator);

    while (grid.positionInBounds(guard.position)) {
        try visitedPositions.put(guard.position, 1);

        const nextPosition = Position{
            .x = guard.position.x + guard.direction.dx(),
            .y = guard.position.y + guard.direction.dy(),
        };

        if (!grid.positionInBounds(nextPosition)) break;

        if (grid.hasObstruction(nextPosition)) {
            guard.direction = guard.direction.turnRight();
        } else {
            guard.position = nextPosition;
        }
    }

    return visitedPositions;
}

fn numberOfOptionsToCauseLooping(grid: Grid) !u32 {
    var options: u32 = 0;
    const positionsVisitedWithoutLooping = try getVisitedPositions(grid);
    var possibleObstructionPositions = std.ArrayList(Position).init(std.heap.page_allocator);

    {
        var it = positionsVisitedWithoutLooping.keyIterator();
        while (it.next()) |visitedPosition| {
            if (visitedPosition.eq(grid.guard.position)) continue;
            const directions = [_]Direction{
                .North,
                .East,
                .South,
                .West,
            };

            for (directions) |direction| {
                const newPosition = Position{
                    .x = visitedPosition.x + direction.dx(),
                    .y = visitedPosition.y + direction.dy(),
                };

                if (!grid.positionInBounds(newPosition)) continue;

                var alreadyExists = false;
                for (possibleObstructionPositions.items) |existingPosition| {
                    if (existingPosition.eq(newPosition)) {
                        alreadyExists = true;
                        break;
                    }
                }

                if (!alreadyExists) {
                    try possibleObstructionPositions.append(newPosition);
                }
            }
        }
    }

    for (possibleObstructionPositions.items) |position| {
        const new_grid = try grid.withObstructionAt(position);
        if (try doesGuardLoop(new_grid)) {
            options += 1;
            std.debug.print("Adding an obstruction at ({d}, {d}) causes the guard to loop!\n", .{ position.x, position.y });
        }
    }

    return options;
}

fn doesGuardLoop(grid: Grid) !bool {
    var guard = grid.guard;

    const VisitedPosition = struct {
        position: Position,
        direction: Direction,
    };

    var visitedPositions = std.AutoHashMap(VisitedPosition, u32).init(std.heap.page_allocator);
    defer visitedPositions.deinit();

    while (grid.positionInBounds(guard.position)) {
        const guardPosition = VisitedPosition{
            .position = guard.position,
            .direction = guard.direction,
        };
        if (visitedPositions.contains(guardPosition)) return true;
        try visitedPositions.put(guardPosition, 1);

        const nextPosition = Position{
            .x = guard.position.x + guard.direction.dx(),
            .y = guard.position.y + guard.direction.dy(),
        };

        if (!grid.positionInBounds(nextPosition)) break;

        if (grid.hasObstruction(nextPosition)) {
            guard.direction = guard.direction.turnRight();
        } else {
            guard.position = nextPosition;
        }
    }

    return false;
}
