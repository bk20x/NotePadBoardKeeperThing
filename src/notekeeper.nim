import raylib, raygui
import util
import window, textwindow
import desktop
import std/[os, streams, strformat]

const DefaultDesktopFileName = "dat.ddt"
proc main =
  const
    GameW = 800'f32
    GameH = 600'f32
    
  var desktop: Desktop
  block loadingDesktop:
    if fileExists DefaultDesktopFileName:
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
      screenW = getRenderWidth()
      screenH = getRenderHeight()
      scaleX  = screenW.float32  / GameW
      scaleY  = screenH.float32 / GameH
      
    block updateCamera:
      cam.zoom = min(scaleX, scaleY)
        
    block savingDesktop:
      if isKeyPressed F2:
        var stream = openFileStream(DefaultDesktopFileName, fmReadWrite)
        defer: close(stream)
        if not fileExists(DefaultDesktopFileName): #first time saving or in a new location, otherwise was doing some really weird shit, where no file was visible in the directory, but was loadable
          writeFile(DefaultDesktopFileName, "")
          desktop.write(stream)
        else:
          desktop.write(stream)

          
    block standardInput:
      if isMouseButtonPressed Right:
        let mousePos = getScreenToWorld2D(getMousePosition(), cam)
        desktop.windows.add newTextWindow(bounds = rect(mousePos.x, mousePos.y, 256, 256))
    
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


