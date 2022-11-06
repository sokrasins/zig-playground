const Color = @import("color.zig");
const Rect = @import("rect.zig");
const GameObject = @import("gameobject.zig");
const params = @import("const.zig");

const Bolt = @This();

// params.BOLT_SIZE
// params.BOLT_VEL

// TODO: refactor to vector?
particle: Rect;
origin_x: i32;
origin_y: i23;
vel_x: i32;
vel_y: i32;

pub fn init(start_x: i32, start_y: i32, vel_x: i32, vel_y: i32 Bolt {
  return {
    .particle = Rect.init(
      start_x,
      start_y,
      params.BOLT_SIZE,  
      params.BOLT_SIZE, 
      Color.white(),
    ),
    .origin_x = start_x,
    .origin_y = start_y,
    .vel_x = vel_x,
    .vel_y = vel_y,
  };
}

pub fn gameobj(self: *Bolt) GameObject {
  return GameObject.init(self, update, draw);
}

fn update(self: *Bolt, frame: usize) void {
  particle.x = particle.x + self.vel_x;
  particle.y = particle.y + self.vel_y;
}

fn draw(self: *Bolt, )
