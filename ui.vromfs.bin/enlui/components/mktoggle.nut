from "%enlSqGlob/ui_library.nut" import *

let { activeBgColor, colPart, titleTxtColor, smallPadding, panelBgColor, defBdColor,
  hoverTxtColor, hoverBdColor, disabledTxtColor, disabledBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { sound_play } = require("sound")


let knobSize = [colPart(0.25), colPart(0.25)]
let blockPadding = smallPadding
let blockSize = [colPart(0.80), knobSize[1] + 2 * blockPadding]
let transitions = [ { prop = AnimProp.translate, duration = 0.15, easing = InOutCubic } ]
let disabledPos = { translate = [knobSize[0] / 2 + blockPadding, 0] }
let activePos = { translate = [blockSize[0] - knobSize[0] / 2 - blockPadding, 0] }


let function mkToggleSwitch(curValue, isEnabled = true){
  let group = ElemGroup()
  let knob = watchElemState(@(sf) {
    watch = curValue
    size = knobSize
    transform = curValue.value ? activePos : disabledPos
    transitions
    group
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [[ VECTOR_ELLIPSE, 0, 50, 50, 50 ]]
    fillColor = !isEnabled ? disabledTxtColor
      : sf & S_ACTIVE ? activeBgColor
      : titleTxtColor
    color = !isEnabled ? disabledBgColor
      : sf & S_ACTIVE ? titleTxtColor
      : sf & S_HOVER ? hoverTxtColor
      : defBdColor
  })

  return watchElemState(@(sf) {
    watch = curValue
    rendObj = ROBJ_BOX
    fillColor = curValue.value ? activeBgColor : panelBgColor
    borderRadius = blockSize[0] * 0.5
    borderColor = sf & S_HOVER ? hoverBdColor : defBdColor
    borderWidth = hdpx(1)
    group
    size = blockSize
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = function() {
      if (isEnabled) {
        curValue(!curValue.value)
        sound_play(curValue.value ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
      }
    }
    children = knob
  })
}

return mkToggleSwitch