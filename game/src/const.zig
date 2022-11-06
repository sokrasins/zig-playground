const Color = @import("color.zig");

// Window properties
pub const WIDTH: c_int = 1280; //640;
pub const HEIGHT: c_int = 800; //400;
pub const BG_COLOR: Color = Color.black();

// Origin of game
pub const BOX_OFFSET_X: i32 = (WIDTH - BOX_SIZE) / 2;
pub const BOX_OFFSET_Y: i32 = (HEIGHT - BOX_SIZE) / 2;

// Box properties
pub const BOX_SIZE: u32 = 120;
pub const NUM_BOXES: usize = 16;
pub const RADIUS: u32 = 300;
pub const SPEED: f32 = 0.06;

// Bolt properties
pub const BOLT_SIZE: u32 = 5;
pub const BOLT_VEL: i32 = 5;
