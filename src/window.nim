import util
import raylib, raymath
import std/[streams, typetraits]


type
  WindowId* = distinct uint32
  
  BaseWindowAction = enum
    None
    Dragging
    Resizing

  Window* = ref object of RootObj
    bounds*:      Rectangle
    dragOffset:   Vector2
    color*:       Color
    scale*:       float32
    action:       BaseWindowAction
    beingDragged: bool
    beingScaled:  bool

method write* (win: Window; stream: Stream) {.base.} = discard
  
method read*  (win: Window; stream: Stream) {.base.} = discard

method update*(win: Window; cam: Camera2D) {.base.} =
  let
    mousePos   = getScreenToWorld2D(getMousePosition(), cam)
    handleSize = 20'f32

    topLeftHandle = rect(
      x      = win.bounds.x, 
      y      = win.bounds.y, 
      width  = handleSize, 
      height = handleSize
    )
    
    bottomRightHandle = rect(
      x      = win.bounds.x + (win.bounds.width  - handleSize), 
      y      = win.bounds.y + (win.bounds.height - handleSize), 
      width  = handleSize, 
      height = handleSize
    )

  if isMouseButtonPressed Left:
    if checkCollisionPointRec(mousePos, topLeftHandle):
      win.action     = Dragging
      win.dragOffset = mousePos - vec2(win.bounds.x, win.bounds.y)
    elif checkCollisionPointRec(mousePos, bottomRightHandle):
      win.action     = Resizing
      win.dragOffset = vec2(win.bounds.width  / win.scale,
                            win.bounds.height / win.scale)

  case win.action
  of Dragging:
    win.bounds.x = mousePos.x - win.dragOffset.x
    win.bounds.y = mousePos.y - win.dragOffset.y
    
  of Resizing:
    let 
      targetW = max(40.0, mousePos.x - win.bounds.x)
      targetH = max(40.0, mousePos.y - win.bounds.y)
      scaleX  = targetW / win.dragOffset.x
      scaleY  = targetH / win.dragOffset.y
    # no asp rat
    win.scale         = (scaleX + scaleY) / 2.0  # just an avg
    win.bounds.width  = targetW
    win.bounds.height = targetH

  of None:
    discard

  if isMouseButtonReleased Left:
    win.action = None

      
method draw*(win: Window) {.base.} =
  drawRectangle(win.bounds, win.color)
  
