const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    const lines = try utils.fileToLines("inputs/day3.txt");
    defer lines.deinit();

    var memory = std.ArrayList(u8).init(std.heap.page_allocator);
    defer memory.deinit();

    for (lines.items) |line| {
        try memory.appendSlice(line);
    }

    std.debug.print("{d}\n", .{executeMulOperations2(memory.items)});
}

fn executeMulOperations(memory: []const u8) u32 {
    var total: u32 = 0;
    var i: usize = 0;

    while (i < memory.len) : (i += 1) {
        // Look for "mul(" pattern
        if (i + 3 < memory.len and
            memory[i] == 'm' and
            memory[i + 1] == 'u' and
            memory[i + 2] == 'l' and
            memory[i + 3] == '(')
        {
            i += 4; // Move past "mul("

            // Parse first number
            var num1: u32 = 0;
            while (i < memory.len and memory[i] >= '0' and memory[i] <= '9') {
                num1 = num1 * 10 + (memory[i] - '0');
                i += 1;
            }

            // Must find comma next
            if (i < memory.len and memory[i] == ',') {
                i += 1;

                // Parse second number
                var num2: u32 = 0;
                while (i < memory.len and memory[i] >= '0' and memory[i] <= '9') {
                    num2 = num2 * 10 + (memory[i] - '0');
                    i += 1;
                }

                // Must end with ')'
                if (i < memory.len and memory[i] == ')') {
                    total += num1 * num2;
                }
            }
        }
    }

    return total;
}

fn executeMulOperations2(memory: []const u8) u32 {
    var total: u32 = 0;
    var i: usize = 0;
    var enabled = true;

    while (i < memory.len) : (i += 1) {
        // Check for do() pattern
        if (i + 3 < memory.len and
            memory[i] == 'd' and
            memory[i + 1] == 'o' and
            memory[i + 2] == '(' and
            memory[i + 3] == ')')
        {
            enabled = true;
            i += 3;
            continue;
        }

        // Check for don't() pattern
        if (i + 6 < memory.len and
            memory[i] == 'd' and
            memory[i + 1] == 'o' and
            memory[i + 2] == 'n' and
            memory[i + 3] == '\'' and
            memory[i + 4] == 't' and
            memory[i + 5] == '(' and
            memory[i + 6] == ')')
        {
            enabled = false;
            i += 6;
            continue;
        }

        // Look for "mul(" pattern
        if (i + 3 < memory.len and
            memory[i] == 'm' and
            memory[i + 1] == 'u' and
            memory[i + 2] == 'l' and
            memory[i + 3] == '(')
        {
            i += 4; // Move past "mul("

            // Parse first number
            var num1: u32 = 0;
            while (i < memory.len and memory[i] >= '0' and memory[i] <= '9') {
                num1 = num1 * 10 + (memory[i] - '0');
                i += 1;
            }

            // Must find comma next
            if (i < memory.len and memory[i] == ',') {
                i += 1;

                // Parse second number
                var num2: u32 = 0;
                while (i < memory.len and memory[i] >= '0' and memory[i] <= '9') {
                    num2 = num2 * 10 + (memory[i] - '0');
                    i += 1;
                }

                // Must end with ')'
                if (i < memory.len and memory[i] == ')') {
                    if (enabled) {
                        total += num1 * num2;
                    }
                }
            }
        }
    }

    return total;
}
