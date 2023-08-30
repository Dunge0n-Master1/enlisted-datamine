from "%enlSqGlob/ui_library.nut" import *

let {fontBody} = require("%enlSqGlob/ui/fontsStyle.nut")
let {HIGHLIGHT_COLOR} = require("%ui/hud/style.nut")


let function optionLabel(opt, _group) {
  let stateFlags = Watched(0)

  return function() {
    let color = (stateFlags.value & S_HOVER) ? HIGHLIGHT_COLOR : Color(160, 160, 160)
    let text = opt?.restart ? $"{opt.name}*" : opt.name
    return {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_LEFT
      //group = group //< for some reason this works only for checkboxes but not for sliders and comboboxes, so disable it for now
      watch = stateFlags
      onElemState = @(sf) stateFlags.update(sf)
      clipChildren = true
      rendObj = ROBJ_TEXT //do not made this stext as it can eat all atlas
      behavior = Behaviors.Marquee
      delay = [3, 1]
      speed = 50
      //stopMouse = true
      text
      color
      sound = {
        hover = "ui/menu_highlight_settings"
      }
    }.__update(fontBody)
  }
}

return optionLabel
