//! Content-addressed code unit hashing and memoization store.
//!
//! Each `CodeUnit` is identified by the SHA-256 hash of its body and the
//! hashes of its dependencies (`docs/design.md`, "Incremental replay").
//! Evaluation verdicts are memoized by `(unit_hash, op_kind)` so unchanged
//! units are reused across commits and branches.

const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const UnitHash = [Sha256.digest_length]u8;

pub const OpKind = enum(u8) {
    harden = 0,
    saturate = 1,
    predict = 2,
    attack = 3,
};

pub const VerdictStatus = enum(u8) {
    passed = 0,
    failed = 1,
    rejected = 2,
};

pub const Verdict = struct {
    status: VerdictStatus,
    score_bps: i32,
    artifact_hash: UnitHash,
};

pub const CodeUnit = struct {
    id: []const u8,
    body: []const u8,
    dep_hashes: []const UnitHash = &.{},

    /// Compute the deterministic content hash of this code unit:
    /// SHA-256(id_len || id || body_len || body || dep_count || dep_hashes...).
    pub fn contentHash(self: CodeUnit) UnitHash {
        var hasher = Sha256.init(.{});
        updateLenPrefixed(&hasher, self.id);
        updateLenPrefixed(&hasher, self.body);

        var dep_count_buf: [8]u8 = undefined;
        std.mem.writeInt(u64, &dep_count_buf, self.dep_hashes.len, .little);
        hasher.update(&dep_count_buf);
        for (self.dep_hashes) |dep| {
            hasher.update(&dep);
        }

        var out: UnitHash = undefined;
        hasher.final(&out);
        return out;
    }
};

fn updateLenPrefixed(hasher: *Sha256, bytes: []const u8) void {
    var len_buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &len_buf, bytes.len, .little);
    hasher.update(&len_buf);
    hasher.update(bytes);
}

pub const MemoKey = struct {
    unit_hash: UnitHash,
    op: OpKind,
};

/// Content-addressed memoization store for unit verdicts.
pub const ContentStore = struct {
    allocator: std.mem.Allocator,
    verdicts: std.AutoHashMapUnmanaged(MemoKey, Verdict) = .{},
    hits: u64 = 0,
    misses: u64 = 0,

    pub fn init(allocator: std.mem.Allocator) ContentStore {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *ContentStore) void {
        self.verdicts.deinit(self.allocator);
    }

    pub fn get(self: *ContentStore, unit_hash: UnitHash, op: OpKind) ?Verdict {
        if (self.verdicts.get(.{ .unit_hash = unit_hash, .op = op })) |v| {
            self.hits += 1;
            return v;
        }
        self.misses += 1;
        return null;
    }

    pub fn put(self: *ContentStore, unit_hash: UnitHash, op: OpKind, verdict: Verdict) !void {
        try self.verdicts.put(self.allocator, .{ .unit_hash = unit_hash, .op = op }, verdict);
    }

    pub fn count(self: *const ContentStore) usize {
        return self.verdicts.count();
    }
};

test "CodeUnit contentHash is deterministic and sensitive to body and deps" {
    const dep_a: UnitHash = [_]u8{0x11} ** 32;
    const dep_b: UnitHash = [_]u8{0x22} ** 32;

    const unit1 = CodeUnit{ .id = "src/foo.zig:add", .body = "return a + b;", .dep_hashes = &.{dep_a} };
    const unit2 = CodeUnit{ .id = "src/foo.zig:add", .body = "return a + b;", .dep_hashes = &.{dep_a} };
    const unit3 = CodeUnit{ .id = "src/foo.zig:add", .body = "return a +% b;", .dep_hashes = &.{dep_a} };
    const unit4 = CodeUnit{ .id = "src/foo.zig:add", .body = "return a + b;", .dep_hashes = &.{dep_b} };

    try std.testing.expectEqualSlices(u8, &unit1.contentHash(), &unit2.contentHash());
    try std.testing.expect(!std.mem.eql(u8, &unit1.contentHash(), &unit3.contentHash()));
    try std.testing.expect(!std.mem.eql(u8, &unit1.contentHash(), &unit4.contentHash()));
}

test "ContentStore memoizes verdicts by unit hash and op" {
    var store = ContentStore.init(std.testing.allocator);
    defer store.deinit();

    const unit = CodeUnit{ .id = "u", .body = "x" };
    const h = unit.contentHash();
    try std.testing.expect(store.get(h, .harden) == null);
    try std.testing.expectEqual(@as(u64, 1), store.misses);

    const v = Verdict{ .status = .passed, .score_bps = 150, .artifact_hash = [_]u8{0xAA} ** 32 };
    try store.put(h, .harden, v);

    const got = store.get(h, .harden) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(VerdictStatus.passed, got.status);
    try std.testing.expectEqual(@as(i32, 150), got.score_bps);
    try std.testing.expectEqual(@as(u64, 1), store.hits);
    try std.testing.expect(store.get(h, .saturate) == null);
}
