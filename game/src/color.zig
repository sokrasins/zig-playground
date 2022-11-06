const std = @import("std");


const Color = @This();

r: u8,
g: u8,
b: u8,
a: u8=255,

pub fn red() Color {
  return Color { .r = 255, .g = 0, .b = 0 };
}

pub fn green() Color {
  return Color { .r = 0, .g = 255, .b = 0 };
}

pub fn blue() Color {
  return Color { .r = 0, .g = 0, .b = 255 };
}

pub fn white() Color {
  return Color { .r = 255, .g = 255, .b = 255 };
}

pub fn black() Color {
  return Color { .r = 0, .g = 0, .b = 0 };
}

pub fn wheel(x: f32) Color {
  var r: u8 = 0;
  var g: u8 = 0;
  var b: u8 = 0;

  const phase = 6.0 * std.math.modf(x).fpart;

  r = @floatToInt(u8, std.math.round(switch (@floatToInt(usize, std.math.floor(phase))) {
    0 => 255.0,
    1 => 255.0 * (1.0 - (phase - 1.0)),
    4 => 255.0 * (phase - 4.0),
    5 => 255.0,
    else => 0.0,
  }));

  g = @floatToInt(u8, std.math.round(switch (@floatToInt(usize, std.math.floor(phase))) {
    0 => 255.0 * phase,
    1 => 255.0,
    2 => 255.0,
    3 => 255.0 * (1.0 - (phase - 3.0)),
    else => 0.0,
  }));

  b = @floatToInt(u8, std.math.round(switch (@floatToInt(usize, std.math.floor(phase))) {
    2 => 255.0 * (phase - 2.0),
    3 => 255.0,
    4 => 255.0,
    5 => 255.0 * (1.0 - (phase - 5.0)),
    else => 0.0,
  }));

  return Color {
    .r = r,
    .g = g,
    .b = b,
  };
}

