const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_contents = try readInputFile(allocator);
    defer allocator.free(file_contents);

    var first_nums = std.ArrayList(u32).init(allocator);
    defer first_nums.deinit();
    var second_nums = std.ArrayList(u32).init(allocator);
    defer second_nums.deinit();

    try parseNumbers(file_contents, &first_nums, &second_nums);

    std.mem.sort(u32, first_nums.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, second_nums.items, {}, std.sort.asc(u32));

    const diff = calculateDifference(first_nums.items, second_nums.items);
    std.debug.print("Diff: {}\n", .{diff});

    const similarity = calculateSimilarityScore(first_nums.items, second_nums.items);
    std.debug.print("Similarity score: {}\n", .{similarity});
}

fn readInputFile(allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1024 * 1024);
}

fn parseNumbers(contents: []const u8, first_nums: *std.ArrayList(u32), second_nums: *std.ArrayList(u32)) !void {
    var iter = std.mem.split(u8, contents, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        var num_iter = std.mem.tokenize(u8, line, " ");
        const first = try std.fmt.parseInt(u32, num_iter.next().?, 10);
        const second = try std.fmt.parseInt(u32, num_iter.next().?, 10);
        try first_nums.append(first);
        try second_nums.append(second);
    }
}

fn calculateDifference(first_nums: []const u32, second_nums: []const u32) u32 {
    var diff: u32 = 0;
    for (first_nums, second_nums) |first, second| {
        diff += @abs(@as(i32, @intCast(first)) - @as(i32, @intCast(second)));
    }
    return diff;
}

fn calculateSimilarityScore(first_nums: []const u32, second_nums: []const u32) u32 {
    var similarity_score: u32 = 0;

    // Create a count map for second_nums
    var count_map = std.AutoHashMap(u32, u32).init(std.heap.page_allocator);
    defer count_map.deinit();

    // Count occurrences in second_nums
    for (second_nums) |num| {
        const entry = count_map.getOrPut(num) catch continue;
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }

    // Calculate similarity score using the count map
    for (first_nums) |num| {
        if (count_map.get(num)) |count| {
            similarity_score += num * count;
        }
    }

    return similarity_score;
}
