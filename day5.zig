const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    const lines = try utils.fileToLines("inputs/day5.txt");
    defer lines.deinit();

    const input = try separateRulesFromOrderings(lines.items);
    const parsedInput = parseInput(input);

    var validOrderings = std.ArrayList(Ordering).init(std.heap.page_allocator);
    var invalidOrderings = std.ArrayList(Ordering).init(std.heap.page_allocator);
    for (parsedInput.requiredOrderings.items) |ordering| {
        if (ordering.isValidForRuleset(parsedInput.rules)) {
            try validOrderings.append(ordering);
        } else {
            try invalidOrderings.append(ordering);
        }
    }

    var validMiddleSum: u64 = 0;
    for (validOrderings.items) |ordering| {
        validMiddleSum += ordering.middleValue();
    }

    std.debug.print("Answer: {}\n", .{validMiddleSum});

    for (invalidOrderings.items) |*ordering| {
        ordering.fixOrdering(parsedInput.rules);
    }

    var invalidMiddleSum: u64 = 0;
    for (invalidOrderings.items) |ordering| {
        invalidMiddleSum += ordering.middleValue();
    }

    std.debug.print("Answer: {}\n", .{invalidMiddleSum});
}

const Rule = struct {
    before: []const u8,
    after: []const u8,
};
const Rules = struct {
    rules: std.ArrayList(Rule),

    fn isFollowed(self: *const Rules, beforePage: []const u8, afterPage: []const u8) bool {
        for (self.rules.items) |rule| {
            if (!std.mem.eql(u8, rule.before, beforePage) and !std.mem.eql(u8, rule.after, beforePage)) continue;
            if (!std.mem.eql(u8, rule.before, afterPage) and !std.mem.eql(u8, rule.after, afterPage)) continue;

            if (std.mem.eql(u8, rule.before, beforePage) and std.mem.eql(u8, rule.after, afterPage)) continue;

            return false;
        }

        return true;
    }
};

const Ordering = struct {
    pages: std.ArrayList([]const u8),

    fn isValidForRuleset(self: *const Ordering, rules: Rules) bool {
        for (self.pages.items, 0..self.pages.items.len) |beforePage, index| {
            if (index == self.pages.items.len - 1) break;
            for (self.pages.items[index + 1 ..]) |afterPage| {
                if (!rules.isFollowed(beforePage, afterPage)) return false;
            }
        }

        return true;
    }

    fn fixOrdering(self: *Ordering, rules: Rules) void {
        // Bubble sort implementation that respects the rules
        var madeSwap = true;
        while (madeSwap) {
            madeSwap = false;
            var i: usize = 0;
            while (i < self.pages.items.len) : (i += 1) {
                // Compare with all following pages, not just adjacent
                var j: usize = i + 1;
                while (j < self.pages.items.len) : (j += 1) {
                    const page1 = self.pages.items[i];
                    const page2 = self.pages.items[j];

                    // If these pages violate a rule, swap them
                    if (!rules.isFollowed(page1, page2)) {
                        const temp = self.pages.items[i];
                        self.pages.items[i] = self.pages.items[j];
                        self.pages.items[j] = temp;
                        madeSwap = true;
                    }
                }
            }
        }
    }

    fn middleValue(self: *const Ordering) u32 {
        const middlePageNumber = self.pages.items[self.pages.items.len / 2];
        return std.fmt.parseInt(u32, middlePageNumber, 10) catch unreachable;
    }
};

const ParsedInput = struct { rules: Rules, requiredOrderings: std.ArrayList(Ordering) };

fn parseInput(input: Input) ParsedInput {
    var rules = std.ArrayList(Rule).init(std.heap.page_allocator);

    for (input.ruleLines) |ruleLine| {
        var it = std.mem.splitSequence(u8, ruleLine, "|");
        const before = it.first();
        const after = it.next() orelse unreachable;
        rules.append(Rule{ .before = before, .after = after }) catch unreachable;
    }

    var orderings = std.ArrayList(Ordering).init(std.heap.page_allocator);
    for (input.orderingLines) |orderingLine| {
        var it = std.mem.splitSequence(u8, orderingLine, ",");
        var pages = std.ArrayList([]const u8).init(std.heap.page_allocator);

        while (it.next()) |page_number| {
            pages.append(page_number) catch unreachable;
        }

        orderings.append(Ordering{ .pages = pages }) catch unreachable;
    }

    return ParsedInput{ .rules = Rules{ .rules = rules }, .requiredOrderings = orderings };
}

const Input = struct { ruleLines: [][]const u8, orderingLines: [][]const u8 };

fn separateRulesFromOrderings(lines: [][]const u8) !Input {
    var ruleLines = std.ArrayList([]const u8).init(std.heap.page_allocator);
    var orderingLines = std.ArrayList([]const u8).init(std.heap.page_allocator);
    var isOrderingSection = false;

    for (lines) |line| {
        if (line.len == 0) {
            isOrderingSection = true;
            continue;
        }

        if (isOrderingSection) {
            orderingLines.append(line) catch unreachable;
        } else {
            ruleLines.append(line) catch unreachable;
        }
    }

    return Input{
        .ruleLines = try ruleLines.toOwnedSlice(),
        .orderingLines = try orderingLines.toOwnedSlice(),
    };
}
