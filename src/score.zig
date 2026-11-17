//! Proper scoring rules, calibration and forecast aggregation.
//!
//! Binary forecasts are probabilities p in [0, 1] of an event; outcomes are
//! 0 or 1. Lower is better for every score here (Brier, log, CRPS). A scoring
//! rule is proper when reporting your true belief minimizes its expectation,
//! so these reward honesty, not hedging toward 0.5 or overconfidence.
//!
//! References: Brier (1950); Good (1952) for the log score; Murphy (1973) for
//! the reliability/resolution/uncertainty decomposition; Gneiting & Raftery
//! (2007) for CRPS; Satopää et al. (2014) for log-odds pooling and
//! extremizing.
const std = @import("std");
const math = std.math;

pub const Error = error{ EmptyInput, LengthMismatch, ProbabilityOutOfRange, NotBinary, BadParameter };

fn checkPair(p: f64, outcome: u1) Error!void {
    _ = outcome;
    if (!(p >= 0 and p <= 1)) return Error.ProbabilityOutOfRange;
}

/// Squared error of one binary forecast: (p - o)^2.
pub fn brier(p: f64, outcome: u1) Error!f64 {
    try checkPair(p, outcome);
    const d = p - @as(f64, @floatFromInt(outcome));
    return d * d;
}

/// Negative log likelihood of one binary forecast, natural log. p is clamped
/// to [eps, 1 - eps] so a confident miss costs a large finite amount instead
/// of infinity; eps = 1e-9 caps one forecast at about 20.7.
pub fn logScore(p: f64, outcome: u1) Error!f64 {
    try checkPair(p, outcome);
    const eps = 1e-9;
    const q = math.clamp(if (outcome == 1) p else 1 - p, eps, 1 - eps);
    return -@log(q);
}

fn meanOf(comptime f: fn (f64, u1) Error!f64, ps: []const f64, os: []const u1) Error!f64 {
    if (ps.len == 0) return Error.EmptyInput;
    if (ps.len != os.len) return Error.LengthMismatch;
    var s: f64 = 0;
    for (ps, os) |p, o| s += try f(p, o);
    return s / @as(f64, @floatFromInt(ps.len));
}

pub fn meanBrier(ps: []const f64, os: []const u1) Error!f64 {
    return meanOf(brier, ps, os);
}

pub fn meanLogScore(ps: []const f64, os: []const u1) Error!f64 {
    return meanOf(logScore, ps, os);
}

/// Brier skill score against a reference forecaster's mean Brier:
/// 1 - BS / BS_ref. Positive beats the reference; 0 ties; negative loses.
pub fn brierSkill(bs: f64, bs_reference: f64) Error!f64 {
    if (!(bs_reference > 0)) return Error.BadParameter;
    return 1 - bs / bs_reference;
}

pub const Bin = struct {
    lo: f64,
    hi: f64,
    count: usize,
    mean_forecast: f64,
    observed_rate: f64,
};

pub const Decomposition = struct {
    brier: f64,
    reliability: f64, // lower is better: gap between forecasts and observed rates
    resolution: f64, // higher is better: how far bins' observed rates move from the base rate
    uncertainty: f64, // base rate x (1 - base rate): fixed by the questions, not the forecaster
    /// brier - (reliability - resolution + uncertainty). Zero when every
    /// forecast in a bin is identical; otherwise it is the within-bin spread.
    residual: f64,
    base_rate: f64,
};

/// Murphy (1973) decomposition over `bins.len` equal-width bins on [0, 1].
/// Fills `bins` (the calibration table) and returns the components.
pub fn decompose(ps: []const f64, os: []const u1, bins: []Bin) Error!Decomposition {
    if (ps.len == 0 or bins.len == 0) return Error.EmptyInput;
    if (ps.len != os.len) return Error.LengthMismatch;
    const k = bins.len;
    const kf: f64 = @floatFromInt(k);
    for (bins, 0..) |*b, i| {
        const fi: f64 = @floatFromInt(i);
        b.* = .{ .lo = fi / kf, .hi = (fi + 1) / kf, .count = 0, .mean_forecast = 0, .observed_rate = 0 };
    }
    var hits: f64 = 0;
    for (ps, os) |p, o| {
        try checkPair(p, o);
        const idx = @min(k - 1, @as(usize, @intFromFloat(@floor(p * kf))));
        bins[idx].count += 1;
        bins[idx].mean_forecast += p;
        bins[idx].observed_rate += @floatFromInt(o);
        hits += @floatFromInt(o);
    }
    const n: f64 = @floatFromInt(ps.len);
    const base = hits / n;
    var rel: f64 = 0;
    var res: f64 = 0;
    for (bins) |*b| {
        if (b.count == 0) continue;
        const c: f64 = @floatFromInt(b.count);
        b.mean_forecast /= c;
        b.observed_rate /= c;
        rel += c * (b.mean_forecast - b.observed_rate) * (b.mean_forecast - b.observed_rate);
        res += c * (b.observed_rate - base) * (b.observed_rate - base);
    }
    rel /= n;
    res /= n;
    const unc = base * (1 - base);
    const bs = try meanBrier(ps, os);
    return .{ .brier = bs, .reliability = rel, .resolution = res, .uncertainty = unc, .residual = bs - (rel - res + unc), .base_rate = base };
}

fn logit(p: f64) f64 {
    return @log(p / (1 - p));
}

fn sigmoid(z: f64) f64 {
    return 1 / (1 + @exp(-z));
}

/// Weighted arithmetic mean of probabilities. Weights need not sum to 1.
pub fn linearPool(ps: []const f64, weights: []const f64) Error!f64 {
    if (ps.len == 0) return Error.EmptyInput;
    if (ps.len != weights.len) return Error.LengthMismatch;
    var s: f64 = 0;
    var w: f64 = 0;
    for (ps, weights) |p, wi| {
        if (!(p >= 0 and p <= 1)) return Error.ProbabilityOutOfRange;
        if (wi < 0) return Error.BadParameter;
        s += wi * p;
        w += wi;
    }
    if (!(w > 0)) return Error.BadParameter;
    return s / w;
}

/// Weighted mean in log-odds space, then scaled by `extremize` (a = 1 is
/// plain log-odds pooling; a > 1 pushes away from 0.5, which corrects the
/// under-confidence of averaging forecasters who hold different evidence).
/// Probabilities must lie strictly inside (0, 1).
pub fn logOddsPool(ps: []const f64, weights: []const f64, extremize: f64) Error!f64 {
    if (ps.len == 0) return Error.EmptyInput;
    if (ps.len != weights.len) return Error.LengthMismatch;
    if (!(extremize > 0)) return Error.BadParameter;
    var s: f64 = 0;
    var w: f64 = 0;
    for (ps, weights) |p, wi| {
        if (!(p > 0 and p < 1)) return Error.ProbabilityOutOfRange;
        if (wi < 0) return Error.BadParameter;
        s += wi * logit(p);
        w += wi;
    }
    if (!(w > 0)) return Error.BadParameter;
    return sigmoid(extremize * s / w);
}

/// Spherical score as a loss (1 - q / ||(p, 1-p)||, lower is better), where q
/// is the probability given to what happened. Proper, and bounded in [0, 1]
/// unlike the log score, so one confident miss cannot dominate a record.
pub fn sphericalLoss(p: f64, outcome: u1) Error!f64 {
    try checkPair(p, outcome);
    const q = if (outcome == 1) p else 1 - p;
    return 1 - q / @sqrt(p * p + (1 - p) * (1 - p));
}

/// Geometric (log-linear) pool of binary forecasts, normalized. For a yes/no
/// event this is exactly the log-odds pool with extremize = 1: averaging
/// evidence in log space. Kept as a separate name because the general
/// multi-outcome geometric pool is not a log-odds average.
pub fn geometricPool(ps: []const f64, weights: []const f64) Error!f64 {
    return logOddsPool(ps, weights, 1);
}

/// Median of the forecasts. Sorts `scratch` (same length as ps) in place.
pub fn median(ps: []const f64, scratch: []f64) Error!f64 {
    return trimmedMean(ps, 0.5, scratch);
}

/// Mean after dropping `trim` of the forecasts from each end (trim in
/// [0, 0.5]; 0.5 gives the median). A robust baseline that is hard to beat.
pub fn trimmedMean(ps: []const f64, trim: f64, scratch: []f64) Error!f64 {
    if (ps.len == 0) return Error.EmptyInput;
    if (scratch.len != ps.len) return Error.LengthMismatch;
    if (!(trim >= 0 and trim <= 0.5)) return Error.BadParameter;
    @memcpy(scratch, ps);
    std.mem.sort(f64, scratch, {}, std.sort.asc(f64));
    const n = scratch.len;
    if (trim == 0.5) {
        return if (n % 2 == 1) scratch[n / 2] else (scratch[n / 2 - 1] + scratch[n / 2]) / 2;
    }
    const k: usize = @intFromFloat(@floor(trim * @as(f64, @floatFromInt(n))));
    if (2 * k >= n) return Error.BadParameter;
    var s: f64 = 0;
    for (scratch[k .. n - k]) |x| s += x;
    return s / @as(f64, @floatFromInt(n - 2 * k));
}

/// Error function. Power series for |x| < 3, continued fraction for erfc
/// beyond; absolute error below 1e-14 across the real line in tests.
pub fn erf(x: f64) f64 {
    if (x < 0) return -erf(-x);
    if (x < 3) {
        // 2/sqrt(pi) * sum_n (-1)^n x^(2n+1) / (n! (2n+1))
        var term = x;
        var sum = x;
        var n: f64 = 0;
        while (n < 200) : (n += 1) {
            term *= -x * x / (n + 1);
            const add = term / (2 * (n + 1) + 1);
            sum += add;
            if (@abs(add) < 1e-17 * @abs(sum)) break;
        }
        return 2.0 / @sqrt(math.pi) * sum;
    }
    return 1 - erfcContinuedFraction(x);
}

fn erfcContinuedFraction(x: f64) f64 {
    // erfc(x) = exp(-x^2)/sqrt(pi) * 1/(x + 1/2/(x + 1/(x + 3/2/(x + ...)))), Lentz's method.
    const tiny = 1e-300;
    var f: f64 = x;
    var c: f64 = x;
    var d: f64 = 0;
    var i: f64 = 1;
    while (i < 500) : (i += 1) {
        const a = i / 2;
        d = x + a * d;
        if (@abs(d) < tiny) d = tiny;
        c = x + a / c;
        if (@abs(c) < tiny) c = tiny;
        d = 1 / d;
        const delta = c * d;
        f *= delta;
        if (@abs(delta - 1) < 1e-16) break;
    }
    return @exp(-x * x) / @sqrt(math.pi) / f;
}

fn normalPdf(z: f64) f64 {
    return @exp(-0.5 * z * z) / @sqrt(2 * math.pi);
}

fn normalCdf(z: f64) f64 {
    return 0.5 * (1 + erf(z / @sqrt(2.0)));
}

/// Continuous ranked probability score of a normal forecast N(mu, sigma^2)
/// against the realized value x (Gneiting & Raftery 2007, closed form). In
/// the units of x. Rewards a point forecast that comes with honest width.
pub fn crpsNormal(mu: f64, sigma: f64, x: f64) Error!f64 {
    if (!(sigma > 0)) return Error.BadParameter;
    const z = (x - mu) / sigma;
    return sigma * (z * (2 * normalCdf(z) - 1) + 2 * normalPdf(z) - 1.0 / @sqrt(math.pi));
}

/// CRPS of an ensemble (equal-weight members) against x:
/// mean |e_i - x| - (1/2) mean |e_i - e_j|. O(n^2); fine for ensembles.
pub fn crpsEnsemble(members: []const f64, x: f64) Error!f64 {
    if (members.len == 0) return Error.EmptyInput;
    const n: f64 = @floatFromInt(members.len);
    var a: f64 = 0;
    var b: f64 = 0;
    for (members) |e| {
        a += @abs(e - x);
        for (members) |f| b += @abs(e - f);
    }
    return a / n - b / (2 * n * n);
}

// ---------------------------------------------------------------------------
// Tests. Expected values were computed independently in Python (float64)
// from the textbook formulas before this file was written.

const t = std.testing;
const P = [_]f64{ 0.9, 0.8, 0.7, 0.6, 0.3, 0.2, 0.1, 0.95, 0.5, 0.05 };
const O = [_]u1{ 1, 1, 0, 1, 0, 0, 0, 1, 1, 0 };

test "Brier and log score match reference values" {
    try t.expectApproxEqAbs(@as(f64, 0.09), try brier(0.7, 1), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.1095), try meanBrier(&P, &O), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.3524215275309778), try meanLogScore(&P, &O), 1e-14);
    try t.expectApproxEqAbs(@as(f64, 0.562), try brierSkill(0.1095, 0.25), 1e-15);
}

test "scores reject impossible inputs" {
    try t.expectError(Error.ProbabilityOutOfRange, brier(1.2, 1));
    try t.expectError(Error.ProbabilityOutOfRange, brier(math.nan(f64), 0));
    try t.expectError(Error.LengthMismatch, meanBrier(&P, O[0..3]));
    try t.expectError(Error.EmptyInput, meanBrier(&.{}, &.{}));
}

test "a confident miss costs a large but finite log score" {
    const s = try logScore(1.0, 0);
    try t.expect(s > 20 and s < 21);
}

test "Murphy decomposition is exact when forecasts sit on single values per bin" {
    const q = [_]f64{ 0.1, 0.1, 0.1, 0.5, 0.5, 0.9, 0.9, 0.9, 0.9, 0.1 };
    const y = [_]u1{ 0, 0, 1, 1, 0, 1, 1, 1, 0, 0 };
    var bins: [10]Bin = undefined;
    const d = try decompose(&q, &y, &bins);
    try t.expectApproxEqAbs(@as(f64, 0.018), d.reliability, 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.05), d.resolution, 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.25), d.uncertainty, 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.218), d.brier, 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0), d.residual, 1e-15);
    try t.expectEqual(@as(usize, 4), bins[1].count);
    try t.expectApproxEqAbs(@as(f64, 0.25), bins[1].observed_rate, 1e-15);
}

test "pooling and extremizing match reference values" {
    const w = [_]f64{ 1, 1 };
    try t.expectApproxEqAbs(@as(f64, 0.7), try linearPool(&.{ 0.6, 0.8 }, &w), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.7101020514433644), try logOddsPool(&.{ 0.6, 0.8 }, &w, 1), 1e-14);
    try t.expectApproxEqAbs(@as(f64, 0.8926638564673071), try logOddsPool(&.{0.7}, &.{1}, 2.5), 1e-14);
    try t.expectError(Error.ProbabilityOutOfRange, logOddsPool(&.{ 0.0, 0.5 }, &w, 1));
}

test "erf matches known values" {
    try t.expectApproxEqAbs(@as(f64, 0), erf(0), 1e-16);
    try t.expectApproxEqAbs(@as(f64, 0.8427007929497149), erf(1), 1e-14);
    try t.expectApproxEqAbs(@as(f64, 0.9953222650189527), erf(2), 1e-14);
    try t.expectApproxEqAbs(@as(f64, 0.9999779095030014), erf(3), 1e-14);
    try t.expectApproxEqAbs(@as(f64, 0.9999999845827421), erf(4), 1e-14);
    try t.expectApproxEqAbs(@as(f64, -0.5204998778130465), erf(-0.5), 1e-14);
}

test "CRPS matches closed-form and ensemble reference values" {
    try t.expectApproxEqAbs(@as(f64, 0.23369497725510913), try crpsNormal(0, 1, 0), 1e-13);
    // The September 2026 10-year Treasury forecast: point 4.66%, realized 5.29%.
    // With a 20bp standard deviation the miss costs 0.517pp of CRPS.
    try t.expectApproxEqAbs(@as(f64, 0.005172511827422364), try crpsNormal(0.0466, 0.002, 0.0529), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.5), try crpsEnsemble(&.{ 1, 2, 4 }, 2.5), 1e-15);
    try t.expectError(Error.BadParameter, crpsNormal(0, 0, 1));
}

test "proper: the expected Brier score is minimized by reporting the true probability" {
    const truth = 0.3;
    var best: f64 = 1;
    var best_s: f64 = math.inf(f64);
    var i: usize = 0;
    while (i <= 100) : (i += 1) {
        const q: f64 = @as(f64, @floatFromInt(i)) / 100;
        const expected = truth * (try brier(q, 1)) + (1 - truth) * (try brier(q, 0));
        if (expected < best_s) {
            best_s = expected;
            best = q;
        }
    }
    try t.expectApproxEqAbs(truth, best, 1e-12);
}

test "spherical loss, geometric pool and robust averages match reference values" {
    try t.expectApproxEqAbs(@as(f64, 1 - 0.9191450300180579), try sphericalLoss(0.7, 1), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 1 - 0.39391929857916774), try sphericalLoss(0.7, 0), 1e-15);
    const ps = [_]f64{ 0.6, 0.8, 0.3 };
    const w = [_]f64{ 1, 2, 1 };
    try t.expectApproxEqAbs(@as(f64, 0.641685908482897), try geometricPool(&ps, &w), 1e-14);
    var scratch: [5]f64 = undefined;
    const xs = [_]f64{ 0.9, 0.1, 0.95, 0.3, 0.2 };
    try t.expectApproxEqAbs(@as(f64, 0.3), try median(&xs, &scratch), 1e-15);
    try t.expectApproxEqAbs(@as(f64, 0.4666666666666666), try trimmedMean(&xs, 0.2, &scratch), 1e-15);
    var s4: [4]f64 = undefined;
    try t.expectApproxEqAbs(@as(f64, 0.25), try median(&.{ 0.1, 0.9, 0.2, 0.3 }, &s4), 1e-15);
}

test "proper: expected spherical and log losses are minimized at the truth" {
    const truth = 0.65;
    inline for (.{ sphericalLoss, logScore }) |f| {
        var best: f64 = 0;
        var best_s: f64 = math.inf(f64);
        var i: usize = 1;
        while (i < 100) : (i += 1) {
            const q: f64 = @as(f64, @floatFromInt(i)) / 100;
            const e = truth * (try f(q, 1)) + (1 - truth) * (try f(q, 0));
            if (e < best_s) {
                best_s = e;
                best = q;
            }
        }
        try t.expectApproxEqAbs(truth, best, 1e-12);
    }
}
