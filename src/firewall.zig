//! Temporal firewall enforcing ADR 0003:
//!
//! 1. Search signals may steer agents only if computable at or before the replay clock.
//! 2. Evaluation signals may only be read after a run is frozen.
//! 3. Distilled skills carry the latest commit stamp they learned from and are
//!    refused by any replay whose clock is earlier.

const std = @import("std");

pub const CommitStamp = struct {
    seq: u64,
    timestamp: i64,
    oid: [40]u8,

    pub fn isAfter(self: CommitStamp, other: CommitStamp) bool {
        if (self.seq != other.seq) return self.seq > other.seq;
        return self.timestamp > other.timestamp;
    }
};

pub const SignalClass = enum {
    search,
    evaluation,
};

pub const DistilledSkill = struct {
    name: []const u8,
    learned_at: CommitStamp,
};

pub const FirewallError = error{
    EvaluationSignalInSearch,
    FutureSignalLeakage,
    SkillFromFuture,
    ClockRegression,
    RunNotFrozen,
};

pub const TemporalFirewall = struct {
    clock: CommitStamp,
    frozen: bool = false,

    pub fn init(initial_clock: CommitStamp) TemporalFirewall {
        return .{ .clock = initial_clock };
    }

    /// Advance the replay clock monotonically. Regressing the clock is rejected.
    pub fn advance(self: *TemporalFirewall, next: CommitStamp) FirewallError!void {
        if (self.frozen) return error.ClockRegression;
        if (self.clock.isAfter(next)) return error.ClockRegression;
        self.clock = next;
    }

    /// Freeze the run so evaluation signals may be read.
    pub fn freeze(self: *TemporalFirewall) void {
        self.frozen = true;
    }

    /// Enforce that a signal used during search is a `.search` signal and does
    /// not originate from any commit after the current replay clock.
    pub fn assertSearchAllowed(
        self: *const TemporalFirewall,
        signal_class: SignalClass,
        signal_commit: CommitStamp,
    ) FirewallError!void {
        if (signal_class == .evaluation) return error.EvaluationSignalInSearch;
        if (signal_commit.isAfter(self.clock)) return error.FutureSignalLeakage;
    }

    /// Enforce that evaluation signals are only read after the run is frozen.
    pub fn assertEvaluationAllowed(self: *const TemporalFirewall) FirewallError!void {
        if (!self.frozen) return error.RunNotFrozen;
    }

    /// Refuse any distilled skill whose `learned_at` stamp is after `self.clock`.
    pub fn validateSkill(self: *const TemporalFirewall, skill: DistilledSkill) FirewallError!void {
        if (skill.learned_at.isAfter(self.clock)) return error.SkillFromFuture;
    }
};

fn testOid(ch: u8) [40]u8 {
    return [_]u8{ch} ** 40;
}

test "TemporalFirewall blocks evaluation signals and future search signals" {
    const t1 = CommitStamp{ .seq = 1, .timestamp = 1000, .oid = testOid('1') };
    const t2 = CommitStamp{ .seq = 2, .timestamp = 2000, .oid = testOid('2') };
    const t3 = CommitStamp{ .seq = 3, .timestamp = 3000, .oid = testOid('3') };

    var fw = TemporalFirewall.init(t2);
    try fw.assertSearchAllowed(.search, t1);
    try fw.assertSearchAllowed(.search, t2);
    try std.testing.expectError(error.FutureSignalLeakage, fw.assertSearchAllowed(.search, t3));
    try std.testing.expectError(error.EvaluationSignalInSearch, fw.assertSearchAllowed(.evaluation, t1));
    try std.testing.expectError(error.RunNotFrozen, fw.assertEvaluationAllowed());

    fw.freeze();
    try fw.assertEvaluationAllowed();
}

test "TemporalFirewall refuses distilled skills from the future and clock regression" {
    const t1 = CommitStamp{ .seq = 1, .timestamp = 1000, .oid = testOid('a') };
    const t2 = CommitStamp{ .seq = 2, .timestamp = 2000, .oid = testOid('b') };
    const t3 = CommitStamp{ .seq = 3, .timestamp = 3000, .oid = testOid('c') };

    var fw = TemporalFirewall.init(t2);
    try fw.validateSkill(.{ .name = "simd-align", .learned_at = t1 });
    try fw.validateSkill(.{ .name = "bounds-elim", .learned_at = t2 });
    try std.testing.expectError(
        error.SkillFromFuture,
        fw.validateSkill(.{ .name = "future-trick", .learned_at = t3 }),
    );
    try std.testing.expectError(error.ClockRegression, fw.advance(t1));
}
