from "%enlSqGlob/ui_library.nut" import *

let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let { CheckBoxContentActive, CheckBoxContentHover, CheckBoxContentDefault, ControlBg
} = require("%ui/style/colors.nut")
let { stateChangeSounds } = require("%ui/style/sounds.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { sound_play } = require("sound")
let { isGamepad } = require("%ui/control/active_controls.nut")

let checkFontSize = hdpx(12)
let boxSize = hdpx(20)
let calcColor = @(sf)
  (sf & S_ACTIVE) ? CheckBoxContentActive
  : (sf & S_HOVER) ? CheckBoxContentHover
  : CheckBoxContentDefault

let box = @(stateFlags, state) function() {
  let color = calcColor(stateFlags.value)
  return {
    watch = stateFlags
    size = [boxSize, boxSize]
    rendObj = ROBJ_BOX
    fillColor = ControlBg
    borderWidth = hdpx(1)
    borderColor = color
    borderRadius = hdpx(3)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = state.value
      ? faComp("check", {color, fontSize = checkFontSize})
      : null
  }
}

let boxHeight = hdpx(25)
let mkCheckMark = @(stateFlags, state, group) @(){
  watch = [stateFlags, state]
  validateStaticText = false
  text = state.value ? fa["check"] : null
  vplace = ALIGN_CENTER
  color = calcColor(stateFlags.value)
  size = [boxHeight,SIZE_TO_CONTENT]
  group
  rendObj = ROBJ_INSCRIPTION
  halign = ALIGN_CENTER
}.__update(fontawesome, {fontSize = checkFontSize})

let mkSwitchKnob = @(stateFlags, state, group) @(){
  size = [boxHeight-hdpx(2),boxHeight-hdpx(2)] rendObj = ROBJ_BOX, borderRadius = hdpx(3),
  borderWidth = hdpx(1),
  fillColor = calcColor(stateFlags.value)
  borderColor = Color(0,0,0,30)
  hplace = state.value ? ALIGN_RIGHT : ALIGN_LEFT
  vplace = ALIGN_CENTER
  watch = [stateFlags, state]
  margin = hdpx(1)
  group
}

let function switchbox(stateFlags, state, group) {
  let checkMark = mkCheckMark(stateFlags, state, group)
  let switchKnob = mkSwitchKnob(stateFlags, state, group)
  return function(){
    return {
      rendObj = ROBJ_BOX
      fillColor = ControlBg
      borderWidth = hdpx(1)
      borderColor = calcColor(stateFlags.value)
      borderRadius = hdpx(3)
      watch = stateFlags
      size = [boxHeight*2+hdpx(2), boxHeight]
      children = [checkMark, switchKnob]
    }
  }
}

local function label(stateFlags, params, group, onClick) {
  if (type(params) != type({})){
    params = { text = params }
  }
  return @() {
    rendObj = ROBJ_TEXT
    margin = [fsh(1), 0, fsh(1), 0]
    color = calcColor(stateFlags.value)
    watch = stateFlags
    group = group
    behavior = [Behaviors.Marquee, Behaviors.Button]
    onClick = onClick
    speed = [hdpx(40),hdpx(40)]
    delay =0.3
    scrollOnHover = true
  }.__update(params)
}

let hotkeyLoc = loc("controls/check/toggleOrEnable/prefix", "Toggle")

return function (state, label_text_params=null, params = {}) {
  let group = params?.group ?? ElemGroup()
  let stateFlags = Watched(0)
  let setValue = params?.setValue ?? @(v) state(v)
  let function onClick(){
    setValue(!state.value)
    sound_play(state.value ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
  }
  let hotkeysElem = params?.useHotkeys ? {
    key = "hotkeys"
    hotkeys = [
      ["Left | J:D.Left", hotkeyLoc, onClick],
      ["Right | J:D.Right", hotkeyLoc, onClick],
    ]
  } : null
  return function(){
    let children = [
      isGamepad.value ? switchbox(stateFlags, state, group) : box(stateFlags, state)
      label(stateFlags, label_text_params, group, onClick)
      stateFlags.value & S_HOVER ? hotkeysElem : null
    ]
    if (params?.textOnTheLeft)
      children.reverse()
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = fsh(1)
      key = state
      group
      watch = [state, stateFlags, isGamepad]
      behavior = [Behaviors.Button]
      size = SIZE_TO_CONTENT
      onElemState = @(sf) stateFlags.update(sf)
      onClick
      sound = stateChangeSounds
      xmbNode = params?.xmbNode
      children
    }.__update(params?.override ?? {})
  }
}
