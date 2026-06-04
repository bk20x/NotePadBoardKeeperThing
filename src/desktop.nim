import window
import textwindow
import std/streams
type
  DesktopObj* = object
    windows*: seq[Window]
    
  Desktop* = ref DesktopObj

  DesktopInfoHeader* = object # will add more important stuff here later
    windowCount: Natural


proc createDesktopWithWindows* (windows: varargs[Window]): Desktop =
  new(result)
  for win in windows:
    result.windows.add(win)


proc readDesktop* (stream: Stream): Desktop =
  new(result)
  if stream.isNil or stream.atEnd():
    return result

  var header: DesktopInfoHeader
  discard stream.readData(addr header, sizeof(DesktopInfoHeader))
  
  result.windows = newSeqOfCap[Window](header.windowCount)
  for i in 0 ..< header.windowCount:
    let winTypeLen = stream.readInt64()
    if winTypeLen <= 0: continue
    
    let winTypeStr = stream.readStr(winTypeLen)
    
    if winTypeStr == "TextWindow": # later, i should make like some sort of manager with all window types like a table where `winTypeStr` is the key
      var textWin: TextWindow
      new(textWin)
      textWin.read(stream)
      result.windows.add textWin

      
proc write* (desktop: Desktop; stream: Stream) =
  if stream == nil: return
  stream.setPosition(0)
  
  var header = DesktopInfoHeader(windowCount: desktop.windows.len)
  stream.writeData(addr header, sizeof(DesktopInfoHeader))
  for win in desktop.windows:
    win.write(stream)
