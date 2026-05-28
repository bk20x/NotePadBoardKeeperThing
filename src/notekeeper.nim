import raylib
import util
import window, textwindow
import desktop
import streams

from std/os import fileExists

proc main =
  const
    GameW = 800'f32
    GameH = 600'f32
    
  var desktop: Desktop
  block loadingDesktop:
    const DefaultDesktopFileName = "dat.ddt"
    if fileExists(DefaultDesktopFileName):
      var stream = openFileStream(DefaultDesktopFileName)
      defer: close(stream)
      desktop = readDesktop(stream)
    else:
      desktop = createDesktopWithWindows()

      
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
      let mousePos = getScreenToWorld2D(getMousePosition(), cam)
      desktop.windows.add newTextWindow(bounds=rect(mousePos.x, mousePos.y, 256, 256))
      
    if isKeyPressed F2:
      block savingDesktop:
        var stream = openFileStream("dat.ddt", fmReadWrite)
        defer: close(stream)
        desktop.write(stream)


    if isKeyDown LeftControl:
      let mousePos = getScreenToWorld2D(getMousePosition(), cam)
      for i in countdown(desktop.windows.high, 0):
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


