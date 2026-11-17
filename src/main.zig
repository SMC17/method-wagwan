const std = @import("std");
const wagwan = @import("wagwan");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const oid1 = [_]u8{'1'} ** 40;
    const oid2 = [_]u8{'2'} ** 40;
    const oid3 = [_]u8{'3'} ** 40;

    const unit_v1 = wagwan.store.CodeUnit{ .id = "src/core.zig:step", .body = "return x + 1;" };
    const unit_v2 = wagwan.store.CodeUnit{ .id = "src/core.zig:step", .body = "return x +| 1;" };
    const helper = wagwan.store.CodeUnit{ .id = "src/core.zig:init", .body = "return 0;" };

    const commits = [_]wagwan.replay.CommitRecord{
        .{ .stamp = .{ .seq = 1, .timestamp = 1_700_000_000, .oid = oid1 }, .units = &.{ unit_v1, helper } },
        .{ .stamp = .{ .seq = 2, .timestamp = 1_700_000_600, .oid = oid2 }, .units = &.{ unit_v2, helper } },
        .{ .stamp = .{ .seq = 3, .timestamp = 1_700_001_200, .oid = oid3 }, .units = &.{ unit_v1, helper } },
    };

    var engine = wagwan.replay.ReplayEngine.init(allocator, wagwan.replay.deterministicHashJudge);
    defer engine.deinit();

    const stats = try engine.replay(&commits);
    const digest = engine.trace.digest();

    var hex_buf: [64]u8 = undefined;
    const hex_chars = "0123456789abcdef";
    for (digest, 0..) |b, i| {
        hex_buf[i * 2] = hex_chars[b >> 4];
        hex_buf[i * 2 + 1] = hex_chars[b & 0x0f];
    }

    std.debug.print(
        "wagwan replay: commits={d} checkpoints={d} evaluated={d} skipped={d} cache_hits={d} trace_digest={s}\n",
        .{
            stats.commits_replayed,
            stats.checkpoints_run,
            stats.units_evaluated,
            stats.units_skipped_unchanged,
            stats.cache_hits,
            hex_buf,
        },
    );
}
