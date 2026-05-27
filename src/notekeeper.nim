import raylib
import util
import window, textwindow
import desktop
import streams, os
import std/typetraits


proc main() =
  const
    GameW = 800'f32
    GameH = 600'f32
  var desktop: Desktop
  block loadingDesktop:
    var stream  = openFileStream("dat.ddt")
    defer: close(stream)
    if stream == nil or stream.atEnd:
      desktop = createDesktopWithWindows()
    else:
      desktop = readDesktop(stream)

    
  
        
  setConfigFlags(flags(WindowResizable))
  initWindow(GameW.int32, GameH.int32, "Notes")
  defer: closeWindow()
  setTargetFPS(60)
  
  var cam = Camera2D(zoom: 1.0)
  while not windowShouldClose():
    let
      scaleX = getRenderWidth().float32  / GameW
      scaleY = getRenderHeight().float32 / GameH
    
    cam.zoom = min(scaleX, scaleY)
    if isMouseButtonPressed Right:
      let p = getScreenToWorld2D(getMousePosition(), cam)
      desktop.windows.add:
        newTextWindow(bounds=rect(p.x, p.y, 256, 256))
      
    if isKeyPressed(F2):
      block savingDesktop:
        var stream = openFileStream("dat.ddt", fmReadWrite)
        defer: close(stream)
        desktop.write(stream)


    if isKeyDown LeftControl:
      let mousePos = getScreenToWorld2D(getMousePosition(), cam)
      for i in countdown(high(desktop.windows), 0):
        if mousePos in desktop.windows[i].bounds and isMouseButtonPressed Right:
          desktop.windows.del(i)
        
      
    for w in desktop.windows:
      w.update(cam)
      
    drawing:
      clearBackground rgba(r=255, g=176, b=222, a=1)
      mode2D(cam):
        for w in desktop.windows:
          w.draw()

main()


