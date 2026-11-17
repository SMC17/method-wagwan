//! Deterministic historical replay engine.
//!
//! Replays a repository's commit history forward from the earliest commit,
//! enforcing the temporal firewall, tracking changed code units by content hash,
//! memoizing verdicts in a `ContentStore`, and recording verified results into
//! an append-only `TraceLog` with a deterministic SHA-256 digest.

const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;
const store = @import("store.zig");
const firewall = @import("firewall.zig");

pub const CommitStamp = firewall.CommitStamp;
pub const TemporalFirewall = firewall.TemporalFirewall;
pub const CodeUnit = store.CodeUnit;
pub const ContentStore = store.ContentStore;
pub const OpKind = store.OpKind;
pub const UnitHash = store.UnitHash;
pub const Verdict = store.Verdict;
pub const VerdictStatus = store.VerdictStatus;

pub const CommitRecord = struct {
    stamp: CommitStamp,
    units: []const CodeUnit,
    is_checkpoint: bool = true,
};

pub const TraceEntry = struct {
    commit: CommitStamp,
    unit_id: []const u8,
    unit_hash: UnitHash,
    op: OpKind,
    verdict: Verdict,
    from_cache: bool,
};

pub const TraceLog = struct {
    allocator: std.mem.Allocator,
    entries: std.ArrayListUnmanaged(TraceEntry) = .empty,

    pub fn init(allocator: std.mem.Allocator) TraceLog {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *TraceLog) void {
        self.entries.deinit(self.allocator);
    }

    pub fn append(self: *TraceLog, entry: TraceEntry) !void {
        try self.entries.append(self.allocator, entry);
    }

    /// Compute a canonical SHA-256 digest over all recorded trace entries.
    /// Two deterministic replays of the same commit stream produce identical digests.
    pub fn digest(self: *const TraceLog) UnitHash {
        var hasher = Sha256.init(.{});
        var count_buf: [8]u8 = undefined;
        std.mem.writeInt(u64, &count_buf, self.entries.items.len, .little);
        hasher.update(&count_buf);

        for (self.entries.items) |e| {
            var seq_buf: [8]u8 = undefined;
            var ts_buf: [8]u8 = undefined;
            var score_buf: [4]u8 = undefined;
            std.mem.writeInt(u64, &seq_buf, e.commit.seq, .little);
            std.mem.writeInt(i64, &ts_buf, e.commit.timestamp, .little);
            std.mem.writeInt(i32, &score_buf, e.verdict.score_bps, .little);

            hasher.update(&seq_buf);
            hasher.update(&ts_buf);
            hasher.update(&e.commit.oid);
            hasher.update(&e.unit_hash);
            hasher.update(&[_]u8{ @intFromEnum(e.op), @intFromEnum(e.verdict.status), @intFromBool(e.from_cache) });
            hasher.update(&score_buf);
            hasher.update(&e.verdict.artifact_hash);
        }

        var out: UnitHash = undefined;
        hasher.final(&out);
        return out;
    }
};

pub const JudgeFn = *const fn (unit: CodeUnit, clock: CommitStamp, op: OpKind) Verdict;

pub const ReplayStats = struct {
    commits_replayed: u64 = 0,
    checkpoints_run: u64 = 0,
    units_evaluated: u64 = 0,
    units_skipped_unchanged: u64 = 0,
    cache_hits: u64 = 0,
    cache_misses: u64 = 0,
    passed_verdicts: u64 = 0,
};

pub const ReplayEngine = struct {
    allocator: std.mem.Allocator,
    content_store: ContentStore,
    trace: TraceLog,
    last_unit_hashes: std.StringHashMapUnmanaged(UnitHash) = .{},
    judge: JudgeFn,

    pub fn init(allocator: std.mem.Allocator, judge: JudgeFn) ReplayEngine {
        return .{
            .allocator = allocator,
            .content_store = ContentStore.init(allocator),
            .trace = TraceLog.init(allocator),
            .judge = judge,
        };
    }

    pub fn deinit(self: *ReplayEngine) void {
        self.last_unit_hashes.deinit(self.allocator);
        self.trace.deinit();
        self.content_store.deinit();
    }

    /// Deterministically replay `commits` in order, enforcing the temporal firewall.
    /// Freezes the firewall when replay finishes and returns summary statistics.
    pub fn replay(self: *ReplayEngine, commits: []const CommitRecord) !ReplayStats {
        if (commits.len == 0) return .{};

        var fw = TemporalFirewall.init(commits[0].stamp);
        var stats = ReplayStats{};

        for (commits) |commit| {
            try fw.advance(commit.stamp);
            stats.commits_replayed += 1;

            if (!commit.is_checkpoint) continue;
            stats.checkpoints_run += 1;

            for (commit.units) |unit| {
                const unit_hash = unit.contentHash();
                if (self.last_unit_hashes.get(unit.id)) |prev_hash| {
                    if (std.mem.eql(u8, &prev_hash, &unit_hash)) {
                        stats.units_skipped_unchanged += 1;
                        continue;
                    }
                }
                try self.last_unit_hashes.put(self.allocator, unit.id, unit_hash);

                try fw.assertSearchAllowed(.search, commit.stamp);

                const ops = [_]OpKind{ .harden, .saturate };
                for (ops) |op| {
                    stats.units_evaluated += 1;
                    if (self.content_store.get(unit_hash, op)) |cached| {
                        stats.cache_hits += 1;
                        if (cached.status == .passed) stats.passed_verdicts += 1;
                        try self.trace.append(.{
                            .commit = commit.stamp,
                            .unit_id = unit.id,
                            .unit_hash = unit_hash,
                            .op = op,
                            .verdict = cached,
                            .from_cache = true,
                        });
                    } else {
                        stats.cache_misses += 1;
                        const verdict = self.judge(unit, fw.clock, op);
                        try self.content_store.put(unit_hash, op, verdict);
                        if (verdict.status == .passed) {
                            stats.passed_verdicts += 1;
                            try self.trace.append(.{
                                .commit = commit.stamp,
                                .unit_id = unit.id,
                                .unit_hash = unit_hash,
                                .op = op,
                                .verdict = verdict,
                                .from_cache = false,
                            });
                        }
                    }
                }
            }
        }

        fw.freeze();
        try fw.assertEvaluationAllowed();
        return stats;
    }
};

/// Default deterministic judge used for unit tests and CLI smoke runs.
/// Computes a deterministic score from the unit's content hash and operation.
pub fn deterministicHashJudge(unit: CodeUnit, _: CommitStamp, op: OpKind) Verdict {
    const h = unit.contentHash();
    const score: i32 = @intCast((@as(u16, h[0]) << 2) % 500 + 10);
    const status: VerdictStatus = if (op == .saturate and (h[1] & 0x03) == 0x03) .rejected else .passed;
    return .{
        .status = status,
        .score_bps = score,
        .artifact_hash = h,
    };
}

/// Parse `git log --reverse --format="%H|%ct"` lines into `CommitStamp`s.
pub fn parseGitLogLines(allocator: std.mem.Allocator, input: []const u8) ![]CommitStamp {
    var list: std.ArrayListUnmanaged(CommitStamp) = .empty;
    errdefer list.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var seq: u64 = 1;
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \r\t");
        if (line.len == 0) continue;

        const sep = std.mem.indexOfScalar(u8, line, '|') orelse return error.InvalidGitLogLine;
        const oid_str = line[0..sep];
        const ts_str = line[sep + 1 ..];
        if (oid_str.len != 40) return error.InvalidOidLength;

        var oid: [40]u8 = undefined;
        @memcpy(&oid, oid_str);
        const ts = try std.fmt.parseInt(i64, ts_str, 10);

        try list.append(allocator, .{
            .seq = seq,
            .timestamp = ts,
            .oid = oid,
        });
        seq += 1;
    }

    return list.toOwnedSlice(allocator);
}

test "ReplayEngine replays commits deterministically and memoizes reverted units" {
    const oid1 = [_]u8{'1'} ** 40;
    const oid2 = [_]u8{'2'} ** 40;
    const oid3 = [_]u8{'3'} ** 40;

    const u_a1 = CodeUnit{ .id = "src/a.zig:fn1", .body = "return 1;" };
    const u_a2 = CodeUnit{ .id = "src/a.zig:fn1", .body = "return 2;" };
    const u_b1 = CodeUnit{ .id = "src/b.zig:fn2", .body = "return 10;" };

    const commits = [_]CommitRecord{
        .{ .stamp = .{ .seq = 1, .timestamp = 100, .oid = oid1 }, .units = &.{ u_a1, u_b1 } },
        .{ .stamp = .{ .seq = 2, .timestamp = 200, .oid = oid2 }, .units = &.{ u_a2, u_b1 } }, // u_b1 unchanged
        .{ .stamp = .{ .seq = 3, .timestamp = 300, .oid = oid3 }, .units = &.{ u_a1, u_b1 } }, // u_a1 reverted -> cache hit
    };

    var engine1 = ReplayEngine.init(std.testing.allocator, deterministicHashJudge);
    defer engine1.deinit();
    const stats1 = try engine1.replay(&commits);

    var engine2 = ReplayEngine.init(std.testing.allocator, deterministicHashJudge);
    defer engine2.deinit();
    const stats2 = try engine2.replay(&commits);

    try std.testing.expectEqual(@as(u64, 3), stats1.commits_replayed);
    try std.testing.expectEqual(@as(u64, 3), stats1.checkpoints_run);
    try std.testing.expectEqual(@as(u64, 2), stats1.units_skipped_unchanged);
    try std.testing.expect(stats1.cache_hits >= 2);
    try std.testing.expectEqual(stats1, stats2);
    try std.testing.expectEqualSlices(u8, &engine1.trace.digest(), &engine2.trace.digest());
}

test "ReplayEngine rejects non-monotonic commit timestamps" {
    const oid1 = [_]u8{'a'} ** 40;
    const oid2 = [_]u8{'b'} ** 40;
    const commits = [_]CommitRecord{
        .{ .stamp = .{ .seq = 2, .timestamp = 200, .oid = oid1 }, .units = &.{} },
        .{ .stamp = .{ .seq = 1, .timestamp = 100, .oid = oid2 }, .units = &.{} },
    };

    var engine = ReplayEngine.init(std.testing.allocator, deterministicHashJudge);
    defer engine.deinit();
    try std.testing.expectError(error.ClockRegression, engine.replay(&commits));
}

test "parseGitLogLines parses git log output into CommitStamps" {
    const sample =
        \\0123456789abcdef0123456789abcdef01234567|1700000000
        \\fedcba9876543210fedcba9876543210fedcba98|1700000120
    ;
    const stamps = try parseGitLogLines(std.testing.allocator, sample);
    defer std.testing.allocator.free(stamps);

    try std.testing.expectEqual(@as(usize, 2), stamps.len);
    try std.testing.expectEqual(@as(u64, 1), stamps[0].seq);
    try std.testing.expectEqual(@as(i64, 1700000000), stamps[0].timestamp);
    try std.testing.expectEqual(@as(u64, 2), stamps[1].seq);
    try std.testing.expectEqual(@as(i64, 1700000120), stamps[1].timestamp);
}
