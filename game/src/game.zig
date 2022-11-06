const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const params = @import("const.zig");

const BoxObj = @import("boxobj.zig");


const Game = @This();

window: *c.SDL_Window,
renderer: *c.SDL_Renderer,
boxes: [params.NUM_BOXES]BoxObj,
frame: usize,

pub fn init(width: c_int, height: c_int) Game {
  var window = c.SDL_CreateWindow("Ball", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, width, height, 0).?;
  var renderer = c.SDL_CreateRenderer(window, 0, c.SDL_RENDERER_PRESENTVSYNC).?;

  var game = Game {
    .window = window,
    .renderer = renderer,
    .frame = 0,
    .boxes = [_]BoxObj{
      BoxObj.init(params.BOX_SIZE, 0),
    } ** params.NUM_BOXES,
  };

  for (game.boxes) |*box, i| {
    box.*.id = i;
  }

  return game;
}

pub fn destroy(self: *Game) void {
  c.SDL_DestroyWindow(self.window);
  c.SDL_DestroyRenderer(self.renderer);
}

pub fn handle_event(self: *Game, event: *c.SDL_Event) void {
  _ = self;
  _ = event;

  // TODO: Call handler on all game objects. They'll need handlers of their own
}

pub fn simulate(self: *Game) void {
  for (self.boxes) |*node| {
    node.gameobj().update(self.frame);
  }
}

pub fn render(self: *Game) void {
  _ = c.SDL_SetRenderDrawColor(self.renderer, params.BG_COLOR.r, params.BG_COLOR.g, params.BG_COLOR.b, params.BG_COLOR.a);
  _ = c.SDL_RenderClear(self.renderer);

  for (self.boxes) |*node| {
    node.gameobj().draw(self.renderer);
  }

  c.SDL_RenderPresent(self.renderer);
}

