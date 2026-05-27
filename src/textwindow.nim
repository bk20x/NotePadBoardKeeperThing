import window
import util
from std/unicode import Rune
import std/[streams, typetraits]
import raylib

type
  TextWindow* {.acyclic.} = ref object of Window
    text*:         string
    textArea*:     Rectangle  
    textSelected*: bool




func newTextWindow* (bounds = rect(width=32, height=32);
                     buf    = newStringOfCap(256);
                     color  = LightGray): TextWindow =    
  TextWindow(
    text:   newStringOfCap(256),
    scale:  1.0,
    color:  color,
    bounds: bounds,
    textSelected: false
  )


proc drawTextWrapped(font: Font;
                     text: string;
                     rec:  Rectangle;
                     fontSize, spacing: float32;
                     tint: Color) =
  type
    WrapState = enum
      Draw,
      Measure
  let length = text.len
  if length == 0: return

  var 
    state       = Measure
    endLine     = -1
    startLine   = -1
    scaleFactor = fontSize / font.baseSize.float32
    textOffsetX = 0.0'f32
    textOffsetY = 0.0'f32
    i = 0

  while i < length:
    let
      ch        = text[i]
      codepoint = ord(ch) 
    

    let idx = getGlyphIndex(font, Rune(codepoint))
    var glyphWidth = 0.0'f32
    if codepoint != 10: 
      if font.glyphs[idx].advanceX == 0:
        glyphWidth = font.recs[idx].width * scaleFactor 
      else:
        glyphWidth = font.glyphs[idx].advanceX.float32 * scaleFactor
      if i + 1 < length: glyphWidth += spacing

    case state
    of Measure:
      if codepoint == 32 or codepoint == 9 or codepoint == 10: 
        endLine = i

      if (textOffsetX + glyphWidth) > rec.width:
        endLine = if endLine < 1: i else: endLine
        if i == endLine: endLine -= 1
        if (startLine + 1) == endLine: endLine = i - 1
        state = Draw
      elif (i + 1) >= length:
        endLine = i
        state = Draw
      elif codepoint == 10: 
        state = Draw

      if state == Draw:
        textOffsetX = 0.0'f32
        i = startLine
        glyphWidth = 0.0'f32

    of Draw:
      if codepoint != 10 and (textOffsetY + font.baseSize.float32 * scaleFactor) <= rec.height:
        if codepoint != 32 and codepoint != 9:
          drawTextCodepoint(font,
                            Rune(codepoint),
                            Vector2(x: rec.x + textOffsetX, y: rec.y + textOffsetY),
                            fontSize,
                            tint)

      if i == endLine:
        textOffsetX = 0.0'f32
        textOffsetY += (font.baseSize.float32 + font.baseSize.float32/2.0'f32) * scaleFactor
        startLine = endLine
        endLine   = -1
        glyphWidth = 0.0'f32
        state = Measure

    textOffsetX += glyphWidth
    i += 1


method update* (win: TextWindow; cam: Camera2D) =
  const Border = 10
  procCall Window(win).update(cam)
  let mousePos = getScreenToWorld2D(getMousePosition(), cam)
  if isMouseButtonPressed(Left):
    win.textSelected = mousePos in win.textArea
  if win.textSelected:
    if isKeyPressed(Backspace):
      if win.text.len > 0:
        win.text.setLen(win.text.high)
        
    let ch = getCharPressed()
    if ch in 32..125:
      win.text.add chr(ch)

  win.textArea = rect(
    x      = win.bounds.x + Border/2,
    y      = win.bounds.y + Border/2,
    width  = win.bounds.width  - Border,
    height = win.bounds.height - Border
  )



var f: ptr Font = nil

method draw* (win: TextWindow) =
  if f == nil:
    f = cast[ptr Font](alloc sizeof(Font))
    f[] = loadFont("/home/bk20x/.local/share/fonts/NotoMono-Regular.ttf")
    
  procCall Window(win).draw()
  drawRectangleLines(win.textArea, 1'f32 * win.scale, Red) # dbg
  let fontScale: float32 = 16*win.scale
    
  if win.textSelected:
    drawRectangle(win.textArea, SkyBlue)
    

  drawTextWrapped(
    f[],
    win.text,
    win.textArea,
    fontScale,
    1.0'f32,
    Black
  )




method write* (win: TextWindow; stream: Stream) =
  let
    tyname    = win.type.name
    tynameLen = tyname.len
  stream.write(tynameLen)
  stream.writeData(addr tyname[0], tynameLen)
    
  stream.writeData(addr win.bounds,   sizeof(Rectangle))
  stream.writeData(addr win.textArea, sizeof(Rectangle))
  stream.writeData(addr win.color,    sizeof(Color))
  stream.writeData(addr win.scale,    sizeof(float32))
  
  let textLen = win.text.len
  stream.write(textLen)
  if textLen > 0:
    stream.writeData(addr win.text[0], textLen)

method read* (win: TextWindow; stream: Stream) =
  discard stream.readData(addr win.bounds,   sizeof(Rectangle))
  discard stream.readData(addr win.textArea, sizeof(Rectangle))
  discard stream.readData(addr win.color,    sizeof(Color))
  discard stream.readData(addr win.scale,    sizeof(float32))
  
  let textLen = stream.readInt64()
  if textLen > 0:
    win.text = stream.readStr(textLen)
  else:
    win.text = ""
    

