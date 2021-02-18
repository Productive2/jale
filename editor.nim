import strformat
import strutils
import tables
import terminal

import line
import multiline
import keycodes
import event
import renderer

type 
  JaleEvent* = enum
    jeKeypress, jeQuit, jeFinish, jePreRead, jePostRead

  LineEditor* = ref object
    # permanents
    keystrokes*: Event[int]
    events*: Event[JaleEvent]
    prompt*: string

    # permanent internals: none
    
    # per-read contents
    content*: Multiline
    lastKeystroke*: int
    # per-read internals
    finished: bool
    rendered: int # how many lines were printed last full refresh
    forceRedraw: bool

# getter/setter sorts

proc unfinish*(le: LineEditor) =
  le.finished = false

proc finish*(le: LineEditor) =
  le.finished = true
  # can be overwritten to false, inside the event
  le.events.call(jeFinish)

proc forceRedraw*(le: LineEditor) =
  le.forceRedraw = true

# constructor

proc newLineEditor*: LineEditor =
  new(result)
  result.content = newMultiline()
  result.keystrokes.new()
  result.events.new()
  result.prompt = ""
  result.rendered = 0
  result.lastKeystroke = -1
  result.forceRedraw = false
  
# priv/pub methods

proc reset(editor: LineEditor) =
  editor.unfinish()
  editor.rendered = 0
  editor.content = newMultiline()
  editor.lastKeystroke = -1
  editor.forceRedraw = false

proc render(editor: LineEditor, line: int = -1, hscroll: bool = true) =
  var y = line
  if y == -1:
    y = editor.content.Y

  renderLine(
    (
      if y == 0:
        editor.prompt
      else:
        " ".repeat(editor.prompt.len())
    ),
    editor.content.getLine(y), 
    0
  )

proc clearLine =
  write stdout, "\r" & " ".repeat(terminalWidth())

proc fullRender(editor: LineEditor) =
  # from the top cursor pos, it draws the entire multiline prompt, then
  # moves cursor to current y
  for i in countup(0, editor.content.high()):
    editor.render(i, false)
    if i < editor.rendered:
      cursorDown(1)
    else:
      write stdout, "\n"
      inc editor.rendered
      
  var extraup = 0
  while editor.content.len() < editor.rendered:
    clearLine()
    cursorDown(1)
    dec editor.rendered
    inc extraup

  cursorUp(editor.content.len() - editor.content.Y + extraup)

proc moveCursorToEnd(editor: LineEditor) =
  # only called when read finished
  if editor.content.high() > editor.content.Y:
    cursorDown(editor.content.high() - editor.content.Y)
  write stdout, "\n"

proc read*(editor: LineEditor): string =

  editor.events.call(jePreRead)

  # starts at the top, full render moves it into the right y
  editor.fullRender()


  while not editor.finished:

    # refresh current line every time
    editor.render()
    setCursorXPos(editor.content.X + editor.prompt.len())
    # get key (with escapes)
    let key = getKey()
    # record y pos
    let preY = editor.content.Y
    # call the events
    editor.lastKeystroke = key
    editor.keystrokes.call(key)
    editor.events.call(jeKeypress)
    # redraw everything if y changed
    if editor.forceRedraw or preY != editor.content.Y:
      # move to the top
      if preY > 0:
        cursorUp(preY)
      # move to the right y
      editor.fullRender()
      if editor.forceRedraw:
        editor.forceRedraw = false

  editor.events.call(jePostRead)

  # move cursor to end
  editor.moveCursorToEnd()
  editor.reset()

  return editor.content.getContent()
