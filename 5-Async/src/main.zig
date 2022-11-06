const std = @import("std");
const expect = std.testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
  var frame = async func();
  _ = frame;
  try expect(foo == 2);
}

fn func() void {
  foo += 1;
  suspend {}
  foo += 1;
}

var bar: i32 = 1;

test "suspend with resume" {
  var frame = async func2();
  resume frame;
  try expect(bar == 3);
}

fn func2() void {
  bar += 1;
  suspend {}
  bar += 1;
}

fn func3() u32 {
  return 5;
}

test "async / await" {
  var frame = async func3();
  try expect(await frame == 5);
}


