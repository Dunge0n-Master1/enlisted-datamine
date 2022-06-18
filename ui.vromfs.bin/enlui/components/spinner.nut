from "%enlSqGlob/ui_library.nut" import *


let faComp = require("%ui/components/faComp.nut")

return kwarg(function mkSpinner(height=hdpx(80), opacity=0.3, color=Color(255,255,255), duration=1, key=null){
  return {
    size = [height, height]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = faComp("spinner", {
      key
      color
      fontSize = height/2
      opacity
      transform = {}
      animations =freeze([
        { prop = AnimProp.rotate, from = 0, to = 360, duration, play = true, loop = true, easing = Discrete8 }
      ])
    })
  }
})
