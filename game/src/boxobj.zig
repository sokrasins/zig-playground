const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const params = @import("const.zig");

const Rect = @import("rect.zig");
const GameObject = @import("gameobject.zig");
const Color = @import("color.zig");


const BoxObj = @This();

form: Rect,
id: usize,

pub fn init(size: u32, id: usize) BoxObj {
  return BoxObj {
    .form = Rect.square(size, Color.white()),
    .id = id,
  };
}

pub fn gameobj(self: *BoxObj) GameObject {
  return GameObject.init(self, update, draw);
}

fn update(self: *BoxObj, frame: usize) void {
  const a = params.SPEED * @intToFloat(f32, frame);
  const t = @intToFloat(f32, self.id) * (2 * std.math.pi / @intToFloat(f32, params.NUM_BOXES));
  const r = @intToFloat(f32, params.RADIUS) * @cos(0.1 * a);

  self.*.form.x = params.BOX_OFFSET_X + @floatToInt(i32, r * @cos(a + t));
  self.*.form.y = params.BOX_OFFSET_Y + @floatToInt(i32, r * @sin(a + t));

  const col = 0.5*a+t/2/std.math.pi;
  self.*.form.color = Color.wheel(col);
}

fn draw(self: *BoxObj, renderer: *c.SDL_Renderer) void {
  const rect = c.SDL_Rect{ 
    .x = @intCast(c_int, self.form.x), 
    .y = @intCast(c_int, self.form.y), 
    .w = @intCast(c_int, self.form.w), 
    .h = @intCast(c_int, self.form.h) 
  };
  _ = c.SDL_SetRenderDrawColor(renderer, self.form.color.r, self.form.color.g, self.form.color.b, self.form.color.a);
  _ = c.SDL_RenderFillRect(renderer, &rect);
}

