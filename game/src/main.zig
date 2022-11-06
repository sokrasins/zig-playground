const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const params = @import("const.zig");

const Game = @import("game.zig");


pub fn main() anyerror!void {
  _ = c.SDL_Init(c.SDL_INIT_VIDEO);
  defer c.SDL_Quit();

  var g = Game.init(params.WIDTH, params.HEIGHT);
  defer g.destroy();

  mainloop: while (true) {

    var sdl_event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&sdl_event) != 0) {
      switch (sdl_event.type) {
        c.SDL_QUIT => break :mainloop,
        else => { g.handle_event(&sdl_event); },
      }
    }

    g.simulate();
    g.render();

    g.frame += 1;
  }
}

