const std = @import("std");

// Pull in types so function signatures look cleaner
const Random = std.rand.Random;
const ParseIntError = std.fmt.ParseIntError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;


/// Errors potentialls generated from equation parsing
const ParseError = error {
  InvalidForm
};


/// Result of the roll
/// total - The final result of the roll operation.
/// rolls - A slice of Roll structs
pub const PoolResult = struct {
  total: i32,
  rolls: []Roll,
};


/// A single die roll
/// value - The number rolled on the die
/// crit_success - True if roll has highest possible value
/// crit_fail - True if roll has lowest possible value
/// used - True if the die roll factors into the final total
pub const Roll = struct {
  value: u32,
  crit_success: bool,
  crit_fail: bool,
  used: bool,
};


/// Helper, count the number of digits at the start of a slice
/// x - slice to count
/// return - number of digits at start
fn countDigits(x: [:0]const u8) usize {
  // Find the number of digits at the start of the slice
  var i: usize = 0;
  while (i < x.len) : (i += 1) {
    if (!std.ascii.isDigit(x[i])) {
      // Stop when we find a non-number char
      break;
    }
  }
  return i;
}


/// Description of the pool of dice. The pool consists of n number of dice with
/// the same number of sides.
/// rolls - Number of dice to roll
/// sides - Number of sides on each die
/// keep_high - If true, keep the highest values. If False, keep the lowest values
/// keep_num - Number of rolls to keep in the pool
/// bias - number to add to the final result. Can be positive or negative
pub const Pool = struct {
  rolls: u32,
  sides: u32,
  keep_high: bool,
  keep_num: u32,
  bias: i32,

  /// Parse the rolls part of a dice equation
  /// eq: Dice equation to parse. Assumes the slice starts with the rolls number
  /// num_rolls: The number of rolls parsed from equation
  /// return: The number of characters consumed by the parsing
  fn parseRolls(eq: [:0]const u8, num_rolls: *u32) usize {
    // Find the number of digits in num rolls
    const i = countDigits(eq);

    // Parse all the digits to an int. We'll assume 1 die if we can't parse.
    num_rolls.* = std.fmt.parseInt(u32, eq[0..i], 10) catch 1;

    // Return the number of consumed characters
    return i;
  }

  /// Parse the 'd' identifying the start of the sides
  /// eq - Dice equation to parse. Assumes the 'd' will be the first character
  /// return - Number of consumed characters
  ///          ParseError if the character is not a 'd'
  fn parseD(eq: [:0]const u8) ParseError!usize {
    // Check if a 'd' is the next character. Otherwise the equation is malformed.
    if (eq[0] == 'd')
      return 1;
    return ParseError.InvalidForm;
  }

  /// Parse the number of sides for each die
  /// eq - Dice equation. Assumes the number of sides starts at the first 
  ///      character
  /// sides - Pointer to returned number of sides
  /// return - number of consumed characters
  ///          ParseError if a number can't be parsed
  fn parseSides(eq: [:0]const u8, sides: *u32) ParseError!usize {
    // Count the number of digits
    const i = countDigits(eq);

    // Parse the number ot an int
    sides.* = std.fmt.parseInt(u32, eq[0..i], 10) catch { 
      // If a number can't be parsed then the parameter is malformed
      return ParseError.InvalidForm;
    };

    // Return the number of consumed bytes
    return i;
  }

  /// Parse if we keep the lowest or highest rolls
  /// eq - dice equation. Assume it starts with the keep order
  /// order - return value, true if highest, false if lowest
  /// return - number of consumed chars
  fn parseKeepOrder(eq: [:0]const u8, order: *bool) ParseError!usize {
    // If there's no k, then the keep expression isn't present
    if (eq[0] != 'k') {
      // Haven't consumed any characters
      return 0;
    }

    // Next character indicates the direction
    order.* = switch (eq[1]) {
      'h' => true,    // "kh" => Keep highest rolls
      'l' => false,   // "kl" => Keep lowest rolls
      else => {
        // Anything else is input error
        return ParseError.InvalidForm;
      },
    };

    return 2;
  }

  /// Parse the number of dice we want to keep
  /// eq - dice equation. Assume it starts with the keep number, and a keep
  ///      order was present.
  /// num - return value, number of dice to keep
  /// return - number of bytes consumed
  fn parseKeepNum(eq: [:0]const u8, num: *u32) ParseError!usize {
    // Find out how many chars are in the number of sides
    const i = countDigits(eq);

    // If not specified assume 1
    if (i == 0) {
      num.* = 1;
      return 0;
    }

    // Parse the number ot an int
    num.* = std.fmt.parseInt(u32, eq[0..i], 10) catch { 
      // If a number can't be parsed then the parameter is malformed
      return ParseError.InvalidForm;
    };

    // Return the number of consumed bytes
    return i;
  }

  /// Parse the bias. This should be the last part of the equation
  /// eq - dice equation. Assume it starts with the bias
  /// bias - returned bias
  /// return - nummber of chars consumed
  fn parseBias(eq: [:0]const u8, bias: *i32) ParseError!usize {
    // Make sure there's something to read in the slice
    if (eq.len == 0) {
      return 0;
    }

    // First character should either be '+' or '-'
    bias.* = switch (eq[0]) {
      '-' => -1,  // We'll always add the bias later, so we can turn the bias to a negative number
      '+' => 1,
      else => {
        // No other characters are allowed
        return ParseError.InvalidForm;
      },
    };

    // Find out how many chars are in the number of sides
    const i = countDigits(eq[1..]) + 1;

    // If we passed the previous section and don't have numbers, then it's an error
    if (i == 0)
      return ParseError.InvalidForm;

    // Parse the bias
    bias.* *= std.fmt.parseInt(i32, eq[1..i], 10) catch { 
      // If a number can't be parsed then the parameter is malformed
      return ParseError.InvalidForm;
    };

    // Return the number of consumed bytes
    return i;
  }

  // Parse the dice pool from a string
  pub fn fromString(eq: [:0]const u8) ParseError!Pool {
    // Track what we've parsed in the pool equation
    var idx: usize = 0;

    // Default to one roll 
    var rolls: u32 = 1; 
    idx += parseRolls(eq[idx..], &rolls);

    idx += parseD(eq[idx..]) catch |err| {
      return err;
    };

    var sides: u32 = 0;
    idx += parseSides(eq[idx..], &sides) catch |err| {
      return err;
    };

    // Set sensible defaults as these may not be present in the eq
    var high = true;        // Add up the highest values. This doesn't matter as we'll...
    var keep: u32 = rolls;  // keep all the dice rolled
    var bias: i32 = 0;      // No bias by default

    const keep_chars = parseKeepOrder(eq[idx..], &high) catch |err| {
      return err;
    };
    idx += keep_chars;

    // Only parse a number if we've detected a keep order
    if (keep_chars > 0) {
      idx += parseKeepNum(eq[idx..], &keep) catch |err| {
        return err;
      };
    }

    idx += parseBias(eq[idx..], &bias) catch |err| {
      return err;
    };

    return Pool {
      .rolls = rolls,
      .sides = sides,
      .keep_high = high,
      .keep_num = keep,
      .bias = bias,
    };
  }
  
  // Resolve the pool into a final value
  pub fn roll(self: *Pool, rng: Random, allocator: Allocator) PoolResult {
    // Store the roll results here
    var list = ArrayList(Roll).init(allocator);

    // Roll all of the dice
    var i: u32 = 0;
    while (i < self.rolls) : (i += 1) {
      // Generate a new random die roll
      var new_roll = rng.intRangeAtMost(u32, 1, self.sides);
      // Add a new roll to our arraylist
      list.append(Roll {
        .value = new_roll,                        // New roll result
        .crit_success = new_roll == self.sides,   // Mark if highest roll
        .crit_fail = new_roll == 1,               // Mark if lowest roll
        .used = false,                            // No rolls are marked used yet
      }) catch unreachable;  
    }

    // We can perform the next operations on a slice, and we'll need to return
    // a slice anyway. 
    const roll_slice = list.toOwnedSlice();

    // Mark rolls we should use
    var num_keep = self.keep_num;
    // calculate the sum at the same time
    var sum: i32 = 0;

    // Iterate over the number of rolls to keep
    while (num_keep > 0) : (num_keep -= 1) {
      // We'll populate this with the next roll index to keep
      var roll_idx: ?usize = null;

      // Search through roll sliace to find the next roll to keep
      for (roll_slice) |die_roll, j| {

        // We only do operations on rolls that haven't been used yet
        if (!die_roll.used) {

          if (roll_idx != null) {
            // Compare our current candidate with the new roll
            var better = false;
            if (self.keep_high) {
              // If we're keeping high rolls, adopt the new one if it's higher
              better = roll_slice[roll_idx.?].value < die_roll.value;
            } else {
              // If we're keeping low rolls, adopt the new one if it's lower
              better = roll_slice[roll_idx.?].value > die_roll.value;
            }

            // If we found a better roll, then track it instead
            if (better) {
              roll_idx = j;
            }

          } else {
            // The first roll we find is the first candidate
            roll_idx = j;
          }
        }
      }
      // TODO: error if idx is null
      // After searching through all of the roll, the current index is chosen.
      roll_slice[roll_idx.?].used = true;
      sum += @intCast(i32, roll_slice[roll_idx.?].value);
    }

    // Finally apply the bias
    sum += self.bias;

    // Return our final pool result
    return PoolResult {
      .total = sum,
      .rolls = roll_slice,
    };
  }
};


