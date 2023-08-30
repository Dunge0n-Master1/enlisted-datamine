from "%enlSqGlob/ui_library.nut" import *

let image = require("image.nut")

let function panel(elem_, ...) {
  local children = elem_?.children ?? []
  let add_children = []
  foreach (v in vargv) {
    if (type(v) != "array")
      add_children.append(v)
    else
      add_children.extend(v)
  }
  if (["table", "class", "function"].contains(type(children)))
    children = [children]

  children.extend(add_children)

  return elem_.__merge({children})
}

return {
  image
  panel
  red = Color(255,0,0)
  blue = Color(0,0,255)
  green = Color(0,255,0)
  magenta = Color(255,0,255)
  yellow = Color(255,255,0)
  cyan = Color(0,255,255)
  gray = Color(128,128,128)
  lightgray = Color(192,192,192)
  darkgray = Color(64,64,64)
  black = Color(0,0,0)
  white = Color(255,255,255)
}
