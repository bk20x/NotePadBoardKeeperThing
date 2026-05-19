import raylib
import raygui except Window
import util, window

type
  TextWindow = ref object of Window
    textArea:     Rectangle  
    text:         string
    textSelected: bool


method update (win: TextWindow; cam: Camera2D) =
  procCall Window(win).update(cam)
  const TextBorder = 10 
  let mousePos = getScreenToWorld2D(getMousePosition(), cam)
  if isMouseButtonPressed(Left):
    win.textSelected = mousePos in win.textArea
  win.textArea = rect(
    x      = win.rect.x + TextBorder/2,
    y      = win.rect.y + TextBorder/2,
    width  = win.rect.width  - TextBorder,
    height = win.rect.height - TextBorder
  )
  

  
method draw (win: TextWindow) =
  procCall Window(win).draw()
  guiSetStyle(
    control  = Default,
    property = TextSize,
    value    = int32(win.scale * 20)
  )
  guiSetStyle(
    control  = Default,
    property = TextWrapMode,
    value    = GuiTextWrapMode.TextWrapNone
  )
  discard textBox(win.textArea,
                  win.text,
                  editMode = win.textSelected)
  guiSetStyle(
    control  = Default,
    property = TextWrapMode,
    value    = GuiTextWrapMode.TextWrapWord
  )
  
const
  GameW = 800'f32
  GameH = 600'f32

var openWindows = @[
  TextWindow(
    scale: 1.0,
    rect:  rect(x = GameW/2 - (256/2),
                y = GameH/2 - (256/2),
                width  = 256,
                height = 256),
    color: LightGray,
    text: newStringOfCap(256)
  )
]


proc main =
  setConfigFlags flags(WindowResizable)
  initWindow(GameW.int32, GameH.int32, "Notes")
  defer: closeWindow()
  setTargetFPS(60)
  
  var cam = Camera2D(zoom: 1.0)
  while not windowShouldClose():
    let
      scaleX = getRenderWidth().float32  / GameW
      scaleY = getRenderHeight().float32 / GameH
    
    cam.zoom = min(scaleX, scaleY)

    for win in openWindows:
      win.update(cam)
      
    drawing:
      clearBackground rgba(r=255, g=176, b=222, a=1)
      mode2D(cam):
        for win in openWindows:
          win.draw()


          
main()
