const std = @import("std");
const c = @cImport({
  @cInclude("AudioToolbox/AudioToolbox.h");
});


pub fn main() !void {
  //inline for (std.meta.fields(@TypeOf(c))) |f| {
  //  std.debug.print(f.name ++ " {}\n", @as(f.field_type, @field(c, f.name)));
  //} 

  std.debug.print("Hello", .{});

}
