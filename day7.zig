const std = @import("std");
const utils = @import("./utils.zig");

// const allocator = std.testing.allocator;
const allocator = std.heap.page_allocator;

const Operator = enum {
    Add,
    Multiply,
    Concatenate,
};

const BinaryCounter = struct {
    slots: u8,
    n: u32 = 0,

    fn next(self: *BinaryCounter) void {
        self.n += 1;
    }

    fn done(self: BinaryCounter) bool {
        const max = std.math.pow(u32, 2, self.slots) - 1;
        return self.n > max;
    }

    fn operatorForSlot(self: BinaryCounter, slot: u8) !Operator {
        const power_of_2 = std.math.pow(u32, 2, slot);
        const value = (self.n / power_of_2) % 2;

        return switch (value) {
            0 => .Add,
            1 => .Multiply,
            else => unreachable,
        };
    }
};

const TrinaryCounter = struct {
    slots: u8,
    n: u32 = 0,

    fn next(self: *TrinaryCounter) void {
        self.n += 1;
    }

    fn done(self: TrinaryCounter) bool {
        const max = std.math.pow(u32, 3, self.slots) - 1;
        return self.n > max;
    }

    fn operatorForSlot(self: TrinaryCounter, slot: u8) !Operator {
        const power_of_3 = std.math.pow(u32, 3, slot);
        const value = (self.n / power_of_3) % 3;

        return switch (value) {
            0 => .Add,
            1 => .Multiply,
            2 => .Concatenate,
            else => unreachable,
        };
    }
};

const EquationElement = union(enum) { operand: i32, operator: Operator, operatorSlot };
const Equation = struct {
    answer: i128,
    elements: []EquationElement,
    cached_slot_indexes: ?[]usize = null,

    fn operator_slot_indexes(self: *Equation) ![]usize {
        if (self.cached_slot_indexes != null) {
            return self.cached_slot_indexes.?;
        }

        var slots = std.ArrayList(usize).init(allocator);
        defer slots.deinit();

        for (self.elements, 0..) |el, i| {
            switch (el) {
                .operatorSlot => try slots.append(i),
                else => {},
            }
        }

        self.cached_slot_indexes = try slots.toOwnedSlice();
        return self.cached_slot_indexes.?;
    }

    fn evaluate(self: Equation) i128 {
        if (self.elements.len == 0) return 0;
        if (self.elements.len == 1) {
            return switch (self.elements[0]) {
                .operand => |value| value,
                else => unreachable,
            };
        }

        var result: i128 = switch (self.elements[0]) {
            .operand => |value| value,
            else => unreachable,
        };

        var i: usize = 1;
        while (i < self.elements.len) : (i += 2) {
            const operator = switch (self.elements[i]) {
                .operator => |op| op,
                else => unreachable,
            };
            const operand = switch (self.elements[i + 1]) {
                .operand => |value| value,
                else => unreachable,
            };

            result = switch (operator) {
                .Add => result + operand,
                .Multiply => result * operand,
                .Concatenate => concatenate: {
                    var buf: [20]u8 = undefined;
                    const result_str = std.fmt.bufPrint(&buf, "{d}", .{result}) catch unreachable;
                    const remaining_buf = buf[result_str.len..];
                    const operand_str = std.fmt.bufPrint(remaining_buf, "{d}", .{operand}) catch unreachable;
                    const combined = buf[0 .. result_str.len + operand_str.len];
                    break :concatenate std.fmt.parseInt(i128, combined, 10) catch unreachable;
                },
            };
        }

        return result;
    }

    fn to_str(self: Equation) []const u8 {
        var buffer = std.ArrayList(u8).init(allocator);
        defer buffer.deinit();

        const answer_str = std.fmt.allocPrint(allocator, "{d} = ", .{self.answer}) catch unreachable;
        defer allocator.free(answer_str);

        buffer.appendSlice(answer_str) catch unreachable;

        for (self.elements) |element| {
            switch (element) {
                .operand => |value| {
                    const str = std.fmt.allocPrint(allocator, "{d}", .{value}) catch unreachable;
                    defer allocator.free(str);
                    buffer.appendSlice(str) catch unreachable;
                },
                .operator => |op| {
                    buffer.append(' ') catch unreachable;
                    switch (op) {
                        .Add => buffer.append('+') catch unreachable,
                        .Multiply => buffer.append('*') catch unreachable,
                        .Concatenate => buffer.appendSlice("||") catch unreachable,
                    }
                    buffer.append(' ') catch unreachable;
                },
                .operatorSlot => {
                    buffer.appendSlice(" ? ") catch unreachable;
                },
            }
        }

        return buffer.toOwnedSlice() catch unreachable;
    }
};

test "Equation.evaluate - single addition" {
    var elements = [_]EquationElement{
        .{ .operand = 5 },
        .{ .operator = .Add },
        .{ .operand = 3 },
    };
    const equation = Equation{
        .answer = 8,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i32, 8), equation.evaluate());
}

test "Equation.evaluate - single multiplication" {
    var elements = [_]EquationElement{
        .{ .operand = 4 },
        .{ .operator = .Multiply },
        .{ .operand = 3 },
    };
    const equation = Equation{
        .answer = 12,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i32, 12), equation.evaluate());
}

test "Equation.evaluate - multiple operations" {
    var elements = [_]EquationElement{
        .{ .operand = 2 },
        .{ .operator = .Add },
        .{ .operand = 3 },
        .{ .operator = .Multiply },
        .{ .operand = 4 },
    };
    const equation = Equation{
        .answer = 20,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i32, 20), equation.evaluate());
}

test "Equation.evaluate - complex expression" {
    var elements = [_]EquationElement{
        .{ .operand = 5 },
        .{ .operator = .Multiply },
        .{ .operand = 2 },
        .{ .operator = .Add },
        .{ .operand = 3 },
        .{ .operator = .Multiply },
        .{ .operand = 4 },
    };
    const equation = Equation{
        .answer = 52,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i32, 52), equation.evaluate());
}

test "Equation.evaluate - concatenation" {
    var elements = [_]EquationElement{
        .{ .operand = 15 },
        .{ .operator = .Concatenate },
        .{ .operand = 6 },
    };
    const equation = Equation{
        .answer = 156,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i128, 156), equation.evaluate());
}

test "Equation.evaluation - complex concatenation" {
    var elements = [_]EquationElement{
        .{ .operand = 6 },
        .{ .operator = .Multiply },
        .{ .operand = 8 },
        .{ .operator = .Concatenate },
        .{ .operand = 6 },
        .{ .operator = .Multiply },
        .{ .operand = 15 },
    };
    const equation = Equation{
        .answer = 7290,
        .elements = &elements,
    };
    try std.testing.expectEqual(@as(i128, 7290), equation.evaluate());
}

fn parseInputLine(line: []const u8) !Equation {
    var equation_elements = std.ArrayList(EquationElement).init(allocator);
    defer equation_elements.deinit();

    const tokens = (try utils.splitOnSpace(line));
    defer tokens.deinit();

    const line_parts = tokens.items;
    const answer = try std.fmt.parseInt(i128, line_parts[0][0 .. line_parts[0].len - 1], 10);
    const rest = line_parts[1..];

    for (rest) |operand| {
        const parsed_operand = try std.fmt.parseInt(i32, operand, 10);
        try equation_elements.append(EquationElement{ .operand = parsed_operand });
        try equation_elements.append(EquationElement.operatorSlot);
    }

    // Remove the extra slot we added to the end
    _ = equation_elements.pop();

    return Equation{ .answer = answer, .elements = try equation_elements.toOwnedSlice() };
}

fn canBeSolved(equation: *Equation) !bool {
    const slot_indexes = try equation.operator_slot_indexes();
    const number_of_operators = slot_indexes.len;

    var counter = BinaryCounter{ .slots = @intCast(number_of_operators) };

    var operators_to_test = try allocator.alloc(Operator, number_of_operators);
    defer allocator.free(operators_to_test);

    while (!counter.done()) {
        for (0..number_of_operators) |i| {
            operators_to_test[i] = try counter.operatorForSlot(@intCast(i));
        }

        if (try tryEquationWithOperators(equation, operators_to_test)) {
            return true;
        }

        counter.next();
    }

    return false;
}

fn canBeSolvedWith3Operators(equation: *Equation) !bool {
    const slot_indexes = try equation.operator_slot_indexes();
    const number_of_operators = slot_indexes.len;

    var counter = TrinaryCounter{ .slots = @intCast(number_of_operators) };

    var operators_to_test = try allocator.alloc(Operator, number_of_operators);
    defer allocator.free(operators_to_test);

    while (!counter.done()) {
        for (0..number_of_operators) |i| {
            operators_to_test[i] = try counter.operatorForSlot(@intCast(i));
        }

        if (try tryEquationWithOperators(equation, operators_to_test)) {
            return true;
        }

        counter.next();
    }

    return false;
}

fn tryEquationWithOperators(equation: *Equation, operators: []Operator) !bool {
    const slot_indexes = try equation.operator_slot_indexes();
    var new_elements = try allocator.alloc(EquationElement, equation.elements.len);
    @memcpy(new_elements, equation.elements);

    for (slot_indexes, 0..) |slot_index, operator_index| {
        new_elements[slot_index] = EquationElement{ .operator = operators[operator_index] };
    }

    const equation_with_operators = Equation{ .answer = equation.answer, .elements = new_elements };

    const result = equation_with_operators.evaluate() == equation.answer;

    allocator.free(new_elements);
    return result;
}

pub fn main() !void {
    const lines = try utils.fileToLines("./inputs/day7.txt");
    defer lines.deinit();

    var solvable: u32 = 0;
    var total_calibration_result: i128 = 0;

    for (lines.items, 0..) |line, i| {
        var equation = try parseInputLine(line);

        if (try canBeSolved(&equation)) {
            solvable += 1;
            total_calibration_result += equation.answer;
        } else {
            std.debug.print("Checking with 3 operators {d} {s}\n", .{ i, equation.to_str() });
            if (try canBeSolvedWith3Operators(&equation)) {
                solvable += 1;
                total_calibration_result += equation.answer;
            }
        }

        allocator.free(equation.elements);
    }

    std.debug.print("Solvable: {d} Result: {d}\n", .{ solvable, total_calibration_result });
}

test "allocation" {
    try main();
}
