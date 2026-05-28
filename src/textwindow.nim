import window
import util
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

  
from std/unicode  import Rune
from std/strutils import splitLines
proc drawTextWrapped*(font: Font;
                      text: string;
                      rec:  Rectangle;
                      fontSize, spacing: float32;
                      tint: Color) =
  if text.len == 0: return

  let 
    scaleFactor = fontSize / font.baseSize.float32
    lineHeight  = (font.baseSize.float32 + font.baseSize.float32 / 2.0'f32) * scaleFactor

  var textOffsetY = 0.0'f32

  for line in text.splitLines():    
    if line.len == 0:
      textOffsetY += lineHeight
      continue

    var 
      i = 0
      lineLength = line.len

    while i < lineLength:
      var 
        spaceIndex = -1
        textWidth  = 0.0'f32
        endIndex   = i

      while endIndex < lineLength:
        let 
          ch = line[endIndex]
          codepoint = ord(ch)

        if codepoint in {32, 9}:
          spaceIndex = endIndex

        let idx = getGlyphIndex(font, Rune(codepoint))
        var glyphWidth = if font.glyphs[idx].advanceX == 0:
                           font.recs[idx].width * scaleFactor 
                         else:
                           font.glyphs[idx].advanceX.float32 * scaleFactor
        if endIndex + 1 < lineLength: glyphWidth += spacing

        if textWidth + glyphWidth > rec.width:
          if spaceIndex > i:
            endIndex = spaceIndex + 1
          else:
            if endIndex == i: endIndex += 1 
          break

        textWidth += glyphWidth
        endIndex += 1

      var textOffsetX = 0.0'f32
      if textOffsetY + lineHeight <= rec.height:
        for renderIndex in i ..< endIndex:
          let ch = line[renderIndex]
          
          if ch != ' ' and ch != '\t':
            drawTextCodepoint(font,
                              Rune(ord(ch)),
                              vec2(rec.x + textOffsetX, rec.y + textOffsetY),
                              fontSize,
                              tint)

          let idx = getGlyphIndex(font, Rune(ord(ch)))
          var glyphWidth = if font.glyphs[idx].advanceX == 0:
                             font.recs[idx].width * scaleFactor 
                           else:
                             font.glyphs[idx].advanceX.float32 * scaleFactor
          if renderIndex + 1 < lineLength: glyphWidth += spacing
          textOffsetX += glyphWidth
          
      # next slot
      textOffsetY += lineHeight
      i = endIndex

method update* (win: TextWindow; cam: Camera2D) =
  const Border = 10
  procCall Window(win).update(cam)
  
  if isMouseButtonPressed(Left):
    let mousePos = getScreenToWorld2D(getMousePosition(), cam)
    win.textSelected = mousePos in win.textArea
    
  if win.textSelected:
    var key = getKeyPressed()
    while key != Null:
      case key
      of Backspace: 
        if win.text.len > 0: win.text.setLen(win.text.high)
      of Enter, KP_Enter: 
        win.text.add "\n"
      of Space: 
        win.text.add " "
      of Tab: 
        win.text.add "    "
      else:
        let keycode = int(key)
        if keycode in 32..126:
          var c = chr(keycode)
          if isKeyDown(LeftShift) or isKeyDown(RightShift):
            const syms = [('1','!'), ('6','^'), ('-','_'),  (';',':'),
                          ('2','@'), ('7','&'), ('=','+'),  ('\'','"'),
                          ('3','#'), ('8','*'), ('[','{'),  (',','<'),
                          ('4','$'), ('9','('), (']','}'),  ('.','>'),
                          ('5','%'), ('0',')'), ('\\','|'), ('/','?')]
            for pair in syms:
              if c == pair[0]: c = pair[1]; break
          elif c >= 'A' and c <= 'Z':
            c = chr(ord(c) + 32) # downcasing
          win.text.add c
      key = getKeyPressed()
      
  win.textArea = rect(win.bounds.x + Border/2,
                      win.bounds.y + Border/2,
                      win.bounds.width  - Border,
                      win.bounds.height - Border)


proc measureEditorTextWidth(font: Font, text: string, fontSize: float32, spacing: float32): float32 =
  var 
    maxWidth = 0.0'f32
    currentLine = ""
  
  for i in 0 ..< text.len:
    if text[i] == '\n':
      let w = measureText(font, currentLine, fontSize, spacing).x
      if w > maxWidth: maxWidth = w
      currentLine = ""
    else:
      currentLine.add(text[i])
      
  let w = measureText(font, currentLine, fontSize, spacing).x
  if w > maxWidth: maxWidth = w
  return maxWidth


var p: pointer = nil
var f: Font
addQuitProc(proc {.noconv.} =
              echo "deallocing little poop for temp i should revamp this later"
              dealloc(p)) # lol


method draw* (win: TextWindow) =
  if p == nil:
    f = loadFont("/home/bk20x/.local/share/fonts/NotoMono-Regular.ttf")
    p = alloc(1)
  
  procCall Window(win).draw()

  let
    baseFontSize = 16.0'f32 * win.scale
    spacing      = 1.0'f32
    maxLineWidth = measureEditorTextWidth(f, win.text, baseFontSize, spacing)

  var fontScale = if maxLineWidth > win.textArea.width:
                    (win.textArea.width / maxLineWidth) * baseFontSize
                  else:
                    baseFontSize

  let maxFontSize = 32.0'f32 * win.scale
  if fontScale > maxFontSize:
    fontScale = maxFontSize
      
  if win.textSelected:
    drawRectangle(win.textArea, SkyBlue)

  drawTextWrapped(
    f,
    win.text,
    win.textArea,
    fontScale,
    spacing,
    Black
  )




method write* (win: TextWindow; stream: Stream) =
  win.writeTypeName(stream)
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
    

