const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    const reports = parseReports() catch unreachable;
    defer reports.deinit();

    const safeReports = countOfSafeReports(reports);
    std.debug.print("{d}\n", .{safeReports});
}

fn parseReports() !std.ArrayList([]u32) {
    const lines = utils.fileToLines("inputs/day2.txt") catch unreachable;
    defer lines.deinit();

    var reports = std.ArrayList([]u32).init(std.heap.page_allocator);

    for (lines.items) |line| {
        const parts = utils.splitOnSpace(line) catch unreachable;
        var report = std.ArrayList(u32).init(std.heap.page_allocator);
        for (parts.items) |part| {
            const level = try std.fmt.parseInt(u32, part, 10);
            try report.append(level);
        }
        try reports.append(report.items);
    }

    return reports;
}

fn countOfSafeReports(reports: std.ArrayList([]u32)) u32 {
    var count: u32 = 0;
    for (reports.items) |report| {
        if (isSafeWithProblemDampner(report)) count += 1;
    }
    return count;
}

fn isSafeWithProblemDampner(report: []u32) bool {
    // If it's already safe without removing any levels, return true
    if (isSafe(report)) return true;

    // Try removing each level one at a time and check if it makes the report safe
    for (0..report.len) |skip_index| {
        // Create a new slice without the current index
        var temp = std.ArrayList(u32).init(std.heap.page_allocator);
        defer temp.deinit();

        for (0..report.len) |i| {
            if (i != skip_index) {
                temp.append(report[i]) catch continue;
            }
        }

        // Check if removing this level makes it safe
        if (isSafe(temp.items)) return true;
    }

    return false;
}
fn isSafe(report: []u32) bool {
    if (report.len < 2) return true;

    // Check if sequence is increasing or decreasing based on first two numbers
    const increasing = report[1] > report[0];

    for (1..report.len) |i| {
        const first = @as(i64, report[i - 1]);
        const second = @as(i64, report[i]);
        const diff = @abs(first - second);

        // Check if difference is between 1 and 3
        if (diff < 1 or diff > 3) return false;

        // Check if sequence maintains direction
        if (increasing and second <= first) return false;
        if (!increasing and second >= first) return false;
    }

    return true;
}
