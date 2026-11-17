//! wagwan-score: score a CSV of binary forecasts.
//!
//!   wagwan-score forecasts.csv [bins]
//!
//! Each line is `probability,outcome` (outcome 0 or 1). Extra columns are
//! ignored, and a first line that does not parse is treated as a header.
const std = @import("std");
const score = @import("wagwan").score;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(arena);
    var errbuf: [512]u8 = undefined;
    var errw = std.Io.File.stderr().writerStreaming(io, &errbuf);
    const err = &errw.interface;
    if (args.len < 2) {
        try err.print("usage: wagwan-score <forecasts.csv> [bins=10]\n", .{});
        try err.flush();
        std.process.exit(2);
    }
    const nbins: usize = if (args.len > 2) try std.fmt.parseInt(usize, args[2], 10) else 10;
    const text = try std.Io.Dir.cwd().readFileAlloc(io, args[1], arena, .limited(64 << 20));

    var ps: std.ArrayList(f64) = .empty;
    var os: std.ArrayList(u1) = .empty;
    var lines = std.mem.tokenizeAny(u8, text, "\r\n");
    var line_no: usize = 0;
    while (lines.next()) |line| {
        line_no += 1;
        var cols = std.mem.splitScalar(u8, line, ',');
        const p_txt = std.mem.trim(u8, cols.next() orelse "", " \t");
        const o_txt = std.mem.trim(u8, cols.next() orelse "", " \t");
        const p = std.fmt.parseFloat(f64, p_txt) catch {
            if (line_no == 1) continue; // header
            try err.print("line {d}: probability '{s}' is not a number\n", .{ line_no, p_txt });
            try err.flush();
            std.process.exit(1);
        };
        const o: u1 = if (std.mem.eql(u8, o_txt, "1")) 1 else if (std.mem.eql(u8, o_txt, "0")) 0 else {
            try err.print("line {d}: outcome '{s}' must be 0 or 1\n", .{ line_no, o_txt });
            try err.flush();
            std.process.exit(1);
        };
        try ps.append(arena, p);
        try os.append(arena, o);
    }

    const bins = try arena.alloc(score.Bin, nbins);
    const d = try score.decompose(ps.items, os.items, bins);
    const logs = try score.meanLogScore(ps.items, os.items);
    const clim = d.base_rate * (1 - d.base_rate);

    var outbuf: [4096]u8 = undefined;
    var outw = std.Io.File.stdout().writerStreaming(io, &outbuf);
    const out = &outw.interface;
    try out.print("forecasts      {d}\nbase rate      {d:.4}\n", .{ ps.items.len, d.base_rate });
    try out.print("Brier          {d:.4}   (always guessing the base rate: {d:.4})\n", .{ d.brier, clim });
    if (clim > 0) try out.print("Brier skill    {d:.4}   (vs base rate; > 0 beats it)\n", .{try score.brierSkill(d.brier, clim)});
    try out.print("log score      {d:.4}\n", .{logs});
    try out.print("reliability    {d:.4}   (calibration error, lower is better)\n", .{d.reliability});
    try out.print("resolution     {d:.4}   (information, higher is better)\n", .{d.resolution});
    try out.print("uncertainty    {d:.4}\n\n", .{d.uncertainty});
    try out.print("bin          n   mean forecast   observed\n", .{});
    for (bins) |b| {
        if (b.count == 0) continue;
        try out.print("{d:.2}-{d:.2}  {d:5}   {d:13.3}   {d:8.3}\n", .{ b.lo, b.hi, b.count, b.mean_forecast, b.observed_rate });
    }
    try out.flush();
}
