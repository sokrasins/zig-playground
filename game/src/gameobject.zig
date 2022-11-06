const std = @import("std");
const assert = std.debug.assert;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const GameObject = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
  update: std.meta.FnPtr(fn (ptr: *anyopaque, frame: usize) void),
  draw: std.meta.FnPtr(fn (ptr: *anyopaque, renderer: *c.SDL_Renderer) void),
};

pub fn init(
  pointer: anytype,
  comptime updateFn: fn (ptr: @TypeOf(pointer), frame: usize) void,
  comptime drawFn: fn (ptr: @TypeOf(pointer), renderer: *c.SDL_Renderer) void,
) GameObject {
  const Ptr = @TypeOf(pointer);
  const ptr_info = @typeInfo(Ptr);

  assert(ptr_info == .Pointer); // Must be a pointer
  assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

  const alignment = ptr_info.Pointer.alignment;

  const gen = struct {
      fn updateImpl(ptr: *anyopaque, frame: usize) void {
          const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
          return @call(.{ .modifier = .always_inline }, updateFn, .{ self, frame });
      }
      fn drawImpl(ptr: *anyopaque, renderer: *c.SDL_Renderer) void {
          const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
          return @call(.{ .modifier = .always_inline }, drawFn, .{ self, renderer });
      }

      const vtable = VTable{
          .update = updateImpl,
          .draw = drawImpl,
      };
  };

  return .{
      .ptr = pointer,
      .vtable = &gen.vtable,
  };
}

pub inline fn update(self: GameObject, frame: usize) void {
  return self.vtable.update(self.ptr, frame);
}

pub inline fn draw(self: GameObject, renderer: *c.SDL_Renderer) void {
  return self.vtable.draw(self.ptr, renderer);
}
