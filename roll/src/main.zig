const std = @import("std");
const cliops = @import("cliops.zig");
const pool = @import("pool.zig");


/// Do thing
pub fn main() !void {
  // Instantiate our CLI struct. This give us a writer and provides all the
  // operations that the cli needs to perform.
  var cli = cliops.Cli.init();

  // Set up memory allocator, used for args and die rolls
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
  defer {
    const leaked = gpa.deinit();
    // Complain if memory has been leaked
    if (leaked) @panic("MEMORY LEAK DETECTED");
  }

  // Get the command-line args
	var args_iter = try std.process.argsWithAllocator(allocator);
	defer args_iter.deinit();

  // Get the args
  var roll_args = cli.parse_args(&args_iter);

  // If help is requested that's all we'll do. Display and quit.
  if (roll_args.help) {
    cli.display_help();
    return;
  }

  // Parse dice equation
  var dp = pool.Pool.fromString(roll_args.pool_eq.?) catch {
    cli.out.print("Error: could not parse dice pool equation.\n", .{}) catch unreachable;
    cli.display_help();
    return;
  };

  // Get a seeded PRNG instance - needed for the dice pool roll method
  var prng = std.rand.DefaultPrng.init(blk: {
    var seed: u64 = undefined;
    try std.os.getrandom(std.mem.asBytes(&seed));
    break :blk seed;
  });
  const rand = prng.random();

  while (roll_args.repeat > 0) : (roll_args.repeat -= 1) {
    // Roll the dice and return
    var result = dp.roll(rand, allocator);
    defer allocator.free(result.rolls);

    // Log the result of the dice roll 
    cli.present(result, roll_args.verbose);
  }
}

