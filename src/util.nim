from raylib import Vector2, Rectangle, Color

template `in`*(point: Vector2; rect: Rectangle): bool =
  checkCollisionPointRec(point, rect)

func vec2*(x: float = 0, y: float = 0): auto {.inline.} =
  Vector2(x: x, y: y)
  
func rect*(x=0f, y=0f, width=0f, height=0f): auto {.inline.} =
  Rectangle(x: x, y: y, width: width, height: height)

func rgba*(r: byte = 0,
           g: byte = 0,
           b: byte = 0,
           a: byte = 0): auto {.inline.} = Color(r: r, g: g, b: b, a: a)

