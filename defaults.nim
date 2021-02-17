import editor
import keycodes
import multiline
import event
import tables
import templates

proc populateDefaults*(editor: LineEditor) =
  editor.bindEvent(jeKeypress):
    if editor.lastKeystroke > 31 and editor.lastKeystroke < 127:
      let ch = char(editor.lastKeystroke)
      editor.content.insert($ch)
  editor.bindKey("left"):
    editor.content.left()
  editor.bindKey("right"):
    editor.content.right()
  editor.bindKey("up"):
    editor.content.up()
  editor.bindKey("down"):
    editor.content.down()
  editor.bindKey("home"):
    editor.content.home()
  editor.bindKey("end"):
    editor.content.`end`()
  editor.bindKey("pageup"):
    editor.content.vhome()
  editor.bindKey("pagedown"):
    editor.content.vend()
  editor.bindKey("backspace"):
    editor.content.backspace()
  editor.bindKey("delete"):
    editor.content.delete()
  editor.bindKey("enter"):
    if editor.content.Y() == editor.content.high() and editor.content.getLine(editor.content.high()) == "":
      editor.finish()
    else:
      editor.content.enter()
  editor.bindKey("ctrl+c"):
    editor.finish()
    editor.events.call(jeQuit)
  editor.bindKey("ctrl+d"):
    if editor.content.getContent() == "":
      editor.finish()
      editor.events.call(jeQuit)
  editor.bindKey("shiftup"):
    editor.historyMove(-1)
  editor.bindKey("shiftdown"):
    editor.historyMove(1)

