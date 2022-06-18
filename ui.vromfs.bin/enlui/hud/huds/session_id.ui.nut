from "%enlSqGlob/ui_library.nut" import *

let {tiny_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let sessionId =  require("%ui/hud/state/session_id.nut")

return function(){
  return {
    text = sessionId.value
    rendObj = ROBJ_TEXT
    opacity = 0.5
    color = Color(120,120,120, 100)
    watch = sessionId
  }.__update(tiny_txt)
}