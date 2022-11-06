const Color = @import("color.zig");

const Rect = @This();

x: i32 = 0,
y: i32 = 0,
w: u32,
h: u32,
color: Color,

pub fn init(x: i32, y: i32, w: u32, h: u32, color: Color) Rect {
  return Rect {
    .x = x,
    .y = y,
    .w = w,
    .h = h,
    .color = color,
  };
}

pub fn square(size: u32, color: Color) Rect {
  return Rect.init(0, 0, size, size, color);
}


