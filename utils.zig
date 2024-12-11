const std = @import("std");

pub fn fileToLines(allocator: std.mem.Allocator, path: []const u8) !std.ArrayList([]const u8) {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(contents);

    var lines = std.ArrayList([]const u8).init(allocator);
    var iterator = std.mem.split(u8, contents, "\n");
    while (iterator.next()) |line| {
        const line_clone = try allocator.alloc(u8, line.len);
        @memcpy(line_clone, line);
        try lines.append(line_clone);
    }
    return lines;
}

pub fn splitOnSpace(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList([]const u8) {
    var iterator = std.mem.split(u8, line, " ");
    var parts = std.ArrayList([]const u8).init(allocator);
    while (iterator.next()) |part| {
        try parts.append(part);
    }
    return parts;
}
