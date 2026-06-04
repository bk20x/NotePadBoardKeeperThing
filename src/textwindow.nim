import window
import util
import std/[streams, typetraits]
import raylib

type
  EditorPos = tuple
    x:      float32
    y:      float32
    height: float32

  EditorPositions = seq[EditorPos]
    
  TextWindow* {.acyclic.} = ref object of Window
    text*:         string
    textArea*:     Rectangle  
    textSelected*: bool
    cursorIdx:     int
    charPositions: EditorPositions

    


func newTextWindow* (bounds = rect(width=32, height=32);
                     buf    = newStringOfCap(256);
                     color  = LightGray): TextWindow =    
  TextWindow(
    text:          buf,
    scale:         1.0,
    color:         color,
    bounds:        bounds,
    textSelected:  false,
    cursorIdx:     0 # init cursor pos
  )

  
from std/unicode  import Rune
from std/strutils import splitLines
proc drawTextWrapped*(win:      TextWindow;
                      font:     Font;
                      fontSize: float32;
                      spacing:  float32;
                      tint:     Color) =
  win.charPositions = newSeq[tuple[x: float32, y: float32, height: float32]](win.text.len + 1)
  let
    textLines   = win.text.splitLines()
    scaleFactor = fontSize / font.baseSize.float32
    lineHeight  = (font.baseSize.float32 + font.baseSize.float32 / 2.0'f32) * scaleFactor

  if win.text.len == 0: 
    win.charPositions = @[(x: win.textArea.x + 2.0'f32, y: win.textArea.y, height: lineHeight)]
    return

  var 
    textOffsetY = 0.0'f32
    globalCharIdx = 0

  for lineIdx, line in textLines:    
    if line.len == 0:
      if globalCharIdx < win.charPositions.len:
        win.charPositions[globalCharIdx] = (x:     win.textArea.x + 2.0'f32,
                                            y:      win.textArea.y + textOffsetY,
                                            height: lineHeight)
      globalCharIdx += 1 
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

      # t wrap scanner
      while endIndex < lineLength:
        let 
          ch = line[endIndex]
          codepoint = ord(ch)

        if codepoint in {32, 9}:
          spaceIndex = endIndex

        let idx = font.getGlyphIndex(Rune(codepoint))
        var glyphWidth = if font.glyphs[idx].advanceX == 0:
                           font.recs[idx].width * scaleFactor 
                         else:
                           font.glyphs[idx].advanceX.float32 * scaleFactor
        if endIndex + 1 < lineLength: glyphWidth += spacing

        if textWidth + glyphWidth > win.textArea.width:
          if spaceIndex > i:
            endIndex = spaceIndex + 1
          else:
            if endIndex == i: endIndex += 1 
          break
        endIndex  += 1
        textWidth += glyphWidth

      var textOffsetX = 0.0'f32
      let fitsInTextArea = (textOffsetY + lineHeight <= win.textArea.height)
      
      for renderIndex in i ..< endIndex:
        let ch = line[renderIndex]
        
        if globalCharIdx < win.charPositions.len:
          win.charPositions[globalCharIdx] = (x: win.textArea.x + textOffsetX, y: win.textArea.y + textOffsetY, height: lineHeight)
        
        if fitsInTextArea:
          drawTextCodepoint(font,
                            Rune(ord(ch)),
                            vec2(win.textArea.x + textOffsetX, win.textArea.y + textOffsetY),
                            fontSize,
                            tint)

        let idx = font.getGlyphIndex(Rune(ord(ch)))
        var glyphWidth = if font.glyphs[idx].advanceX == 0:
                           font.recs[idx].width * scaleFactor 
                         else:
                           font.glyphs[idx].advanceX.float32 * scaleFactor
        if renderIndex + 1 < lineLength: glyphWidth += spacing
        textOffsetX += glyphWidth
        globalCharIdx += 1

      # edge space tracking
      if endIndex >= lineLength and globalCharIdx < win.charPositions.len:
        win.charPositions[globalCharIdx] = (x: win.textArea.x + textOffsetX + 2.0'f32, y: win.textArea.y + textOffsetY, height: lineHeight)

      textOffsetY += lineHeight
      i = endIndex
      
    globalCharIdx += 1

  if globalCharIdx <= win.text.len:
    win.charPositions[win.text.len] = (x: win.textArea.x + 2.0'f32, y: win.textArea.y + textOffsetY - lineHeight, height: lineHeight)

  if win.textSelected and win.cursorIdx < win.charPositions.len:
    let pos = win.charPositions[win.cursorIdx]
    let cursorWidth = 2.0'f32 * scaleFactor
    if pos.y + pos.height <= win.textArea.y + win.textArea.height:
      drawRectangleLines(
        rect(x      = pos.x,
             y      = pos.y,
             width  = cursorWidth,
             height = pos.height), 
        color     = Black,
        lineThick = 1'f32, 
      )


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



method update* (win: TextWindow; cam: Camera2D) =
  const Border = 10.0
  procCall Window(win).update(cam)
  
  if isMouseButtonPressed(Left):
    let mousePos = getScreenToWorld2D(getMousePosition(), cam)
    win.textSelected = mousePos in win.textArea
    
    if win.textSelected and win.charPositions.len > 0:
      var
        closestIdx = 0
        minDistance = 999999.0'f32
      for i, pos in win.charPositions:
        if mousePos.y in pos.y .. (pos.y + pos.height):
          let dist = abs(mousePos.x - pos.x)
          if dist < minDistance:
            minDistance = dist
            closestIdx  = i
      if minDistance == 999999.0'f32:
        win.cursorIdx = win.text.len
      else:
        win.cursorIdx = closestIdx
    
  if win.textSelected:
    var key = getKeyPressed()
    while key != Null:
      case key
      of Up, Down:
        if win.cursorIdx in 0 ..< win.charPositions.len:
          let
            currentPos = win.charPositions[win.cursorIdx]
            targetY    = if key == Up:
                           currentPos.y - currentPos.height
                         else:
                           currentPos.y + currentPos.height
          var
            bestIdx     = win.cursorIdx
            closestDist = 999999.0'f32
          for i, pos in win.charPositions:
            if abs(pos.y - targetY) < 2.0'f32:
              let dist = abs(pos.x - currentPos.x)
              if dist < closestDist:
                closestDist = dist
                bestIdx = i
          win.cursorIdx = bestIdx
      of Left:
        if win.cursorIdx > 0: dec(win.cursorIdx)
      of Right:
        if win.cursorIdx < win.text.len: inc(win.cursorIdx)
      of Backspace: 
        if win.cursorIdx > 0:
          win.text = win.text[0 ..< win.cursorIdx - 1] & win.text[win.cursorIdx .. ^1]
          dec win.cursorIdx
      of Delete:
        if win.cursorIdx < win.text.len:
          win.text = win.text[0 ..< win.cursorIdx] & win.text[win.cursorIdx + 1 .. ^1]
      of Enter, KP_Enter: 
        win.text.insert("\n", win.cursorIdx)
        inc(win.cursorIdx)
      of Tab: 
        win.text.insert("    ", win.cursorIdx)
        win.cursorIdx += 4
      of Home:
        while win.cursorIdx > 0 and win.text[win.cursorIdx - 1] != '\n':
          dec(win.cursorIdx)
      of End:
        while win.cursorIdx < win.text.len and win.text[win.cursorIdx] != '\n':
          inc(win.cursorIdx)
      else: discard
      key = getKeyPressed()

    var charCode = getCharPressed()
    while charCode > 0:
      const StdPrintableAscii = {32..125}
      case charCode
      of StdPrintableAscii: 
        win.text.insert($chr(charCode), win.cursorIdx)
        inc(win.cursorIdx)
      else: discard
      charCode = getCharPressed()
      
  win.textArea = rect(win.bounds.x + Border/2,
                      win.bounds.y + Border/2,
                      win.bounds.width  - Border,
                      win.bounds.height - Border)



var fInit = false
var f: Font



method draw* (win: TextWindow) =
  if not fInit:
    f = loadFont("/home/bk20x/.local/share/fonts/NotoMono-Regular.ttf")
    fInit = true
  
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

  win.drawTextWrapped(
    f,
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
  
  let textLen = win.text.len.int64
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
    win.text = stream.readStr(textLen.int)
  else:
    win.text = ""
