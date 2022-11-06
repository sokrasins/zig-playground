const std = @import("std");
const term = @import("ansi-term");

const pool = @import("pool.zig");

// Pull out types for cleaner function decls
const Allocator = std.mem.Allocator;
const ArgIterator = std.process.ArgIterator;
const Writer = std.fs.File.Writer;

const PoolResult = pool.PoolResult;

const style = term.style;


/// Parsed roll arguments
/// pool_eq - the equation for the die pool. This may be null if it could not 
///           be parsed
/// verbose - Display individual die rolls
/// help    - Print the usage of this function. This is the default behavior if 
///           there is a parsing error.
pub const RollArgs = struct {
  pool_eq: ?[:0]const u8,
  verbose: bool,
  help: bool,
  repeat: u32,
};


pub const Cli = struct {
  out: Writer,

  /// Get stdout
  pub fn init() Cli {
    var stdout = std.io.getStdOut().writer();
    return Cli {
      .out = stdout,
    };
  }

  /// Parse the CLI args
  pub fn parse_args(self: *Cli, args: *ArgIterator) RollArgs {
    // Hard-coded args TODO: generalize
    _ = self;

    // Flag that signifies an optional parameter
    const arg_flag = "-";

    // Initialize the return struct variables
    var verbose = false;
    var help = false;
    var pool_eq: ?[:0]const u8 = null;
    var repeat: u32 = 1;

    // Throw away the bin path
    if (!args.skip())
      unreachable;

    // Parse all args
    var arg_num: u32 = 0;
    while (args.next()) |arg| {
      //std.debug.print("next arg: {s}\n", .{arg});

      // Advance our arg counter at the end of each iteration
      defer arg_num += 1;

      // Check for the existence of positional args
      if (arg_num == 0) {
        if (std.mem.eql(u8, arg, "stats")) {
          pool_eq = "4d6kh3";
          verbose = true;
          repeat = 6;
          continue;
        } else if (arg[0] != '-') {
          // This looks like a pool equation, so parse next arg
          pool_eq = arg;
          continue;
        } else {
          // This doesn't look like aroll equation. This probably means we should
          // display the help. Whatever we got might be an optional parameter so
          // let the following logic determine that.
          help = true;
        }
      }

      // Check for optional flags
      if (std.mem.eql(u8, arg, arg_flag ++ "v")) {
        // Verbosity requested
        verbose = true;
      } else if (std.mem.eql(u8, arg, arg_flag ++ "h")) {
        // Display the help
        help = true;
      } else if (std.mem.eql(u8, arg, arg_flag ++ "r")) {
        const repeat_num = args.next();
        if (repeat_num == null) {
          help = true;
        } else {
          repeat = std.fmt.parseInt(u32, repeat_num.?, 10) catch blk: {
            help = true;
            break :blk 1;
          };
        }
      } else {
        // If there's something we don't understand then display the help
        help = true;
      }
    }

    // If there were no args then display help
    if (arg_num == 0)
      help = true;

    return RollArgs {
      .pool_eq = pool_eq,
      .verbose = verbose,
      .help = help,
      .repeat = repeat,
    };
  }

  /// Display the usage of this program. We should show:
  /// - Expected usage
  /// - Optional arguments
  /// - Example usage
  pub fn display_help(self: *Cli) void {
    self.out.print(
      \\Polyhedral roller of dice
      \\Usage: roll [equation|"stats"] -r [repetitions] -v -h      
      \\    equation: of the form [num dice]d[sides]k[h|l][number][+|-][bias]
      \\      num dice: number of dice to roll (default: 1)
      \\      sides: number of sides on each die
      \\      kh/kl: Keep high or low rolls
      \\      number: number of dice to keep for total (default: all)
      \\      +/- bias: add or subtract a number from the final result 
      \\    stats: preset for 4d6kh3 -r 6 -v
      \\Parameters:
      \\    -r: Number of times to roll the pool
      \\    -v: verbose output
      \\    -h: display this text
      \\
      , .{}
    ) catch unreachable;
  }

  /// Display the final roll result. If verbosity isrequested, then we want to
  /// show the individual rolls as well as color-coded crit hit/fail info
  pub fn present(self: *Cli, result: PoolResult, verbose: bool) void {
    if (verbose) {
      // Print the list of individual rolls
      self.out.print("[ ", .{}) catch unreachable;
      for (result.rolls) |roll| {
        var roll_style = style.Style{};

        // Set the style of the roll result
        if (roll.crit_success) {
          // Green for crit success rolls
          roll_style.foreground = style.Color.Green;
        } else if (roll.crit_fail) {
          // Red for crit fail rolls
          roll_style.foreground = style.Color.Red;
        }
        if (!roll.used) {
          // Dim the roll if it doesn't factor into the final value
          roll_style.font_style = style.FontStyle.dim;
        }

        // Only set the style if it's changed
        if (!roll_style.isDefault()) {
          term.format.updateStyle(self.out, roll_style, null) catch unreachable;
        }

        // Print the roll
        self.out.print("{d} ", .{roll.value}) catch unreachable;

        // If we changed the style, clear it for the next iteration
        if (!roll_style.isDefault()) {
          // Clear formatting if we changed it
          term.format.resetStyle(self.out) catch unreachable;
        } 
      }
      self.out.print("]  ", .{}) catch unreachable;

      self.out.print("total: ", .{}) catch unreachable;
    }

    // If not verbose then only show the final result
    self.out.print("{d}\n", .{result.total}) catch unreachable;
  }
};


