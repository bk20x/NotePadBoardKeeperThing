import util
import raylib, raymath

type
  #WindowId* = distinct uint32
  
  BaseWindowAction = enum
    None
    Dragging
    Resizing

  Window* = ref object of RootObj
    rect*:        Rectangle
    dragOffset:   Vector2
    color*:       Color
    scale*:       float32
    action:       BaseWindowAction
    beingDragged: bool
    beingScaled:  bool



method update*(win: Window; cam: Camera2D) {.base.} =
  let
    handleSize = 20'f32
    mousePos   = getScreenToWorld2D(getMousePosition(), cam)

    topLeftHandle = rect(
      x      = win.rect.x, 
      y      = win.rect.y, 
      width  = handleSize, 
      height = handleSize
    )
    
    bottomRightHandle = rect(
      x      = win.rect.x + (win.rect.width  - handleSize), 
      y      = win.rect.y + (win.rect.height - handleSize), 
      width  = handleSize, 
      height = handleSize
    )

  if isMouseButtonPressed Left:
    if checkCollisionPointRec(mousePos, topLeftHandle):
      win.action     = Dragging
      win.dragOffset = mousePos - vec2(win.rect.x, win.rect.y)
    elif checkCollisionPointRec(mousePos, bottomRightHandle):
      win.action     = Resizing
      win.dragOffset = vec2(win.rect.width  / win.scale,
                            win.rect.height / win.scale)

  case win.action
  of Dragging:
    win.rect.x = mousePos.x - win.dragOffset.x
    win.rect.y = mousePos.y - win.dragOffset.y
    
  of Resizing:
    let 
      targetW = max(40.0, mousePos.x - win.rect.x)
      targetH = max(40.0, mousePos.y - win.rect.y)
      scaleX  = targetW / win.dragOffset.x
      scaleY  = targetH / win.dragOffset.y
    # no asp rat
    win.scale       = (scaleX + scaleY) / 2.0  # just an avg
    win.rect.width  = targetW
    win.rect.height = targetH

  of None:
    discard

  if isMouseButtonReleased Left:
    win.action = None

      
method draw*(win: Window) {.base.} =
  drawRectangle(win.rect, win.color)
  
