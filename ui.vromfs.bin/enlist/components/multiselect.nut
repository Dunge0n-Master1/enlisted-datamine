from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let {CheckBoxContentActive, CheckBoxContentHover, CheckBoxContentDefault, ControlBg} = require("%ui/style/colors.nut")
let { gap, bigGap } = require("%enlSqGlob/ui/viewConst.nut")
let {sound_play} = require("sound")
let multiselect = require("%ui/components/multiselect.nut")
let {stateChangeSounds} = require("%ui/style/sounds.nut")

let {font, fontSize} = body_txt
let checkFontSize = hdpx(12)
let boxSize = hdpx(20)
let calcColor = @(sf)
  (sf & S_ACTIVE) ? CheckBoxContentActive
  : (sf & S_HOVER) ? CheckBoxContentHover
  : CheckBoxContentDefault

let function box(isSelected, sf) {
  let color = calcColor(sf)
  return {
    size = [boxSize, boxSize]
    rendObj = ROBJ_BOX
    fillColor = ControlBg
    borderWidth = hdpx(1)
    borderColor = color
    borderRadius = hdpx(3)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = isSelected
      ? faComp("check", {color, fontSize = checkFontSize})
      : null
  }
}

let label = @(text, sf) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = calcColor(sf)
  text
  font
  fontSize
  behavior = [Behaviors.Marquee]
  scrollOnHover = true
}

let function optionCtor(option, isSelected, onClick) {
  let stateFlags = Watched(0)
  return function() {
    let sf = stateFlags.value

    return {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [fsh(0.5),fsh(1.0),fsh(0.5),fsh(1.0)]
      watch = stateFlags
      behavior = Behaviors.Button
      onElemState = @(s) stateFlags(s)
      onClick = function() {
        sound_play(isSelected ? "ui/enlist/flag_unset" : "ui/enlist/flag_set")
        onClick()
      }
      sound = stateChangeSounds
      stopHover = true

      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = bigGap
      children = [
        box(isSelected, sf)
        label(option.text, sf)
      ]
    }
  }
}

let style = {
  root = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = gap
  }
  optionCtor = optionCtor
}

return @(params) multiselect({ style = style }.__update(params))