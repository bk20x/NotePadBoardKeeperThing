import window
import textwindow
import std/streams
type
  DesktopObj* = object
    windows*: seq[Window]
    
  Desktop* = ref DesktopObj


proc createDesktopWithWindows* (windows: varargs[Window]): Desktop =
  new(result)
  for win in windows:
    result.windows.add(win)


type
  DesktopInfoHeader* = object # will add more important stuff here later
    windowCount: Natural



proc readDesktop* (stream: Stream): Desktop =
  new(result)
  if stream == nil or stream.atEnd():
    return result

  var header: DesktopInfoHeader
  discard stream.readData(addr header, sizeof(DesktopInfoHeader))
  
  result.windows = newSeq[Window]()
  for i in 0 ..< header.windowCount:
    let winTypeLen = stream.readInt64()
    if winTypeLen <= 0: continue
    
    let winTypeStr = stream.readStr(winTypeLen)
    
    if winTypeStr == "TextWindow":
      var textWin: TextWindow
      new(textWin)
      textWin.read(stream)
      result.windows.add(Window(textWin))

      
proc write* (desktop: Desktop; stream: Stream) =
  if stream == nil: return
  stream.setPosition(0)
  
  var header = DesktopInfoHeader(windowCount: desktop.windows.len)
  stream.writeData(addr header, sizeof(DesktopInfoHeader))
  
  for win in desktop.windows:
    win.write(stream)
