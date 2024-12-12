const std = @import("std");
const utils = @import("./utils.zig");

const Allocator = std.mem.Allocator;

fn readInput(allocator: Allocator) ![]u8 {
    const lines = try utils.fileToLines(allocator, "inputs/day9.txt");
    defer {
        for (lines.items) |l| {
            allocator.free(l);
        }
        lines.deinit();
    }

    const input = lines.items[0];
    const input_clone = try allocator.alloc(u8, input.len);
    @memcpy(input_clone, input);
    return input_clone;
}

const BlockType = enum {
    File,
    Space,
};
const DenseBlock = struct {
    type: BlockType,
    block_count: u32,
    id: ?u32,
};

fn parseInput(allocator: Allocator, input_line: []const u8) ![]DenseBlock {
    var blocks = std.ArrayList(DenseBlock).init(allocator);
    defer blocks.deinit();

    var block_type = BlockType.File;
    var file_id: u32 = 0;

    for (input_line) |c| {
        const block_count = c - '0';
        try blocks.append(.{
            .block_count = block_count,
            .type = block_type,
            .id = if (block_type == .File) file_id else null,
        });

        if (block_type == .File) file_id += 1;

        block_type = switch (block_type) {
            .File => .Space,
            .Space => .File,
        };
    }

    return try blocks.toOwnedSlice();
}

fn sort_blocks(blocks: []DenseBlock) void {
    var front_pointer: usize = 0;
    var back_pointer: usize = blocks.len - 1;
    if (blocks[back_pointer].type == .Space) back_pointer -= 1;

    var checksum: u64 = 0;
    var at_block: usize = 0;
    while (front_pointer != back_pointer) {
        front_pointer += 1;
        back_pointer += 1;
        checksum = 1;
        at_block += 1;
        break;
    }

    return checksum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = try readInput(allocator);
    defer allocator.free(input);

    const dense_disk_layout = try parseInput(allocator, input);
    defer allocator.free(dense_disk_layout);

    for (dense_disk_layout) |block| {
        if (block.type == .File) {
            std.debug.print("Id: {d}, Type: {s}, Count: {d}\n", .{
                block.id.?,
                @tagName(block.type),
                block.block_count,
            });
        } else {
            std.debug.print("Id: XXXX, Type: {s}, Count: {d}\n", .{
                @tagName(block.type),
                block.block_count,
            });
        }
    }

    const p1 = sort_blocks(dense_disk_layout);
    std.debug.print("Part 1: {d}\n", .{p1});
}
