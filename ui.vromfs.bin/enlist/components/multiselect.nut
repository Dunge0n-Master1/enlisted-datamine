from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let { CheckBoxContentActive, CheckBoxContentHover, CheckBoxContentDefault, ControlBg,
  TextInactive } = require("%ui/style/colors.nut")
let { gap, bigGap } = require("%enlSqGlob/ui/viewConst.nut")
let { sound_play } = require("sound")
let multiselect = require("%ui/components/multiselect.nut")
let { stateChangeSounds } = require("%ui/style/sounds.nut")

let checkFontSize = hdpx(12)
let boxSize = hdpx(20)
let calcColor = @(sf)
  (sf & S_ACTIVE) ? CheckBoxContentActive
  : (sf & S_HOVER) ? CheckBoxContentHover
  : CheckBoxContentDefault

let box = @(isSelected, color) {
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

let label = @(text, color) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color
  text
  behavior = [Behaviors.Marquee]
  scrollOnHover = true
}.__update(body_txt)

let function optionCtor(option, isSelected, onClick) {
  let stateFlags = Watched(0)
  return function() {
    let sf = stateFlags.value
    let color = calcColor(sf)
    return {
      size = [flex(), SIZE_TO_CONTENT]
      margin = [fsh(1), 0]
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
        box(isSelected, color)
        label(option.text, color)
      ]
    }
  }
}

let optionCtorDisabled = @(option, isSelected, _onClick) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [fsh(1), 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigGap
  children = [
    box(isSelected, TextInactive)
    label(option.text, TextInactive)
  ]
}

let styleCommon = {
  root = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = gap
  }
  optionCtor = optionCtor
}

let styleDisabled = styleCommon.__merge({
  optionCtor = optionCtorDisabled
})

let mkMultiselect = @(params) multiselect({ style = styleCommon }.__update(params))

return {
  multiselect = mkMultiselect
  styleCommon
  styleDisabled
}