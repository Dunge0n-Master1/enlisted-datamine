from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { DEFAULT_TEXT_COLOR, TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR } = require("%ui/hud/style.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { controlHint } = require("%ui/components/templateControls.nut")
let { makeSvgImgFromText } = require("%ui/control/formatInputBinding.nut")
let { is_action_binding_set, get_action_handle } = require("dainput2")
let { generation } = require("%ui/hud/menus/controls_state.nut")

let hotkeyGap     = hdpx(20)
let hotkeyListGap = hdpx(5)

let defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]


let mkBigControlIcon = @(text, params = {})
  (text ?? "") == "" ? null : makeSvgImgFromText(text, {height=hdpx(36)}.__update(params))

let hasHotkey = @(key, isGamepad)
  is_action_binding_set(get_action_handle(key, 0xFFFF), isGamepad ? 1 : 0)

let function makeDefText(item) {
  let color = item?.color ?? (
    "myTeamScores" not in item ? DEFAULT_TEXT_COLOR
      : item.myTeamScores ? TEAM0_TEXT_COLOR
      : TEAM1_TEXT_COLOR)
  let animations = item?.animations ?? defTextAnims
  let text = type(item)=="table" ? item?.text : item
  let hintText = {
    size = [flex(), SIZE_TO_CONTENT]
    maxWidth = SIZE_TO_CONTENT
    rendObj = ROBJ_TEXTAREA
    valign = ALIGN_CENTER
    behavior = Behaviors.TextArea
    fontFx = FFT_BLUR
    fontFxColor = Color(0,0,0,50)
    fontFxFactor = min(64, hdpx(64))
    fontFxOffsY = hdpx(0.9)
    text
    color
  }.__update(h2_txt)
  local hintComponent = hintText

  local { hotkey = null } = item
  if (hotkey != null) {
    hintComponent = function() {
      let res = { watch = [isGamepad, generation] }
      if (typeof hotkey != "array")
        hotkey = [hotkey]
      hotkey = hotkey
        .map(function(h) {
          if (typeof h == "array")
            h = h.findvalue(@(key) hasHotkey(key, isGamepad.value))
          if (typeof h != "string")
            return null
          return controlHint(h, { imgFunc = mkBigControlIcon })
        })
        .filter(@(h) h != null)
      if (hotkey.len() == 0)
        return res.__update(hintText)

      let hotkeyHint = {
        halign = ALIGN_CENTER
        flow = isGamepad.value ? FLOW_HORIZONTAL : FLOW_VERTICAL
        gap = hotkeyListGap
        children = hotkey
      }
      let hotkeySize = calc_comp_size(hotkeyHint)
      let hotkeyWidth = hotkeySize[0] + hotkeyGap
      hotkeyHint.pos <- [-hotkeyWidth, (calc_comp_size(hintText)[1] - hotkeySize[1]) / 2]
      return hintText.__merge(res, {
        pos = [hotkeyWidth / 2, 0]
        children = hotkeyHint
      })
    }
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    animations = animations
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

