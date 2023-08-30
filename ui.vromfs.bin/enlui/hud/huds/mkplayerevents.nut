from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { BRIGHT_TEXT_COLOR, TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR } = require("%ui/hud/style.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { controlHint } = require("%ui/components/templateControls.nut")
let { makeSvgImgFromText } = require("%ui/control/formatInputBinding.nut")
let { is_action_binding_set, get_action_handle } = require("dainput2")
let { generation } = require("%ui/hud/menus/controls_state.nut")

let hotkeyGap     = hdpx(5)
let hotkeyListGap = hdpx(5)

let defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]


let mkBigControlIcon = @(text, params = {})
  (text ?? "") == "" ? null : makeSvgImgFromText(text, {height=hdpx(36)}.__update(params))

let hasHotkey = @(key, isGamepadV)
  is_action_binding_set(get_action_handle(key, 0xFFFF), isGamepadV ? 1 : 0)
let gkImg = function(h) {
  if (typeof h == "array")
    h = h.findvalue(@(key) hasHotkey(key, isGamepad.value))
  if (typeof h != "string")
    throw null
  return controlHint(h, { imgFunc = mkBigControlIcon })
}

let function makeDefText(item) {
  let color = item?.color ?? (
    "myTeamScores" not in item ? BRIGHT_TEXT_COLOR
      : item.myTeamScores ? TEAM0_TEXT_COLOR
      : TEAM1_TEXT_COLOR)
  let animations = item?.animations ?? defTextAnims
  let text = type(item)=="table" ? item?.text : item
  let hintText = {
    size = [flex(), SIZE_TO_CONTENT]
    maxWidth = SIZE_TO_CONTENT
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    fontFx = FFT_BLUR
    fontFxColor = Color(0, 0, 0, 150)
    fontFxFactor = min(64, hdpx(64))
    fontFxOffsY = hdpx(0.9)
    text
    color
  }.__update(fontHeading2)
  local hintComponent = hintText

  local { hotkey = null } = item
  let hgt = calc_str_box("A", fontHeading2)[1].tointeger()
  if (hotkey != null) {
    hintComponent = function() {
      let watch = [isGamepad, generation]
      if (typeof hotkey != "array")
        hotkey = [hotkey]
      hotkey = hotkey.map(gkImg)
      if (hotkey.len() == 0)
        return {watch}.__update(hintText)

      let hotkeyHint = {
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hotkeyListGap
        children = hotkey
      }
      let hotkeySize = calc_comp_size(hotkeyHint)
      let hotkeyWidth = hotkeySize[0] + hotkeyGap
//      hotkeyHint.pos <- [-hotkeyWidth, (calc_comp_size(hintText)[1] - hotkeySize[1]) / 2]
      hotkeyHint.pos <- [-hotkeyWidth, (hgt - hotkeySize[1]*0.8) / 2] //use 0.9 to compensate visual smaller text than H height
      return hintText.__merge({
        pos = [hotkeyWidth / 2, 0]
        children = hotkeyHint
        watch
      })
    }
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    animations
    key = item
    transform = { pivot = [0, 1] }
    children = hintComponent
  }
}

let function makeItem(item){
  if ("ctor" in item)
    return item.ctor(item)
  return makeDefText(item)
}

return {
  makeItem
}

