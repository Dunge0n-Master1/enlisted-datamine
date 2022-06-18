from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let getGamepadHotkeys = require("%ui/components/getGamepadHotkeys.nut")
let {mkImageCompByDargKey} = require("%ui/components/gamepadImgByKey.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")

return function(textComp, params, handler, group, sf){
  local gamepadHotkey = getGamepadHotkeys(params?.hotkeys)
  let activeKB = ((sf & S_KB_FOCUS) != 0)
  let hoverKB = ((sf  & S_HOVER) != 0 && (params?.isEnabled ?? true))
  local fontStyle = params?.textParams.fontStyle ?? params?.fontStyle ?? body_txt
  let font = params?.textParams.font ?? params?.font
  let fontSize = params?.textParams.fontSize ?? params?.fontSize
  if (fontSize!=null && font!=null)
    fontStyle = {font, fontSize}
  let height = fontSize ?? fontStyle.fontSize
  if ((hoverKB || activeKB) && (params?.isEnabled ?? true))
    gamepadHotkey = JB.A
  if (gamepadHotkey == "")
    return textComp
  let src_margin = textComp?.margin
  local margin = (typeof(src_margin) == "array") ? clone src_margin : src_margin ?? 0
  if (typeof(margin) != "array")
    margin = [margin, margin, margin, margin]
  else if (margin.len()==2)
    margin = [margin[0], margin[1], margin[0], margin[1]]
  else if (margin.len()==1)
    margin = [margin[0], margin[0], margin[0], margin[0]]

  let gamepadBtn = mkImageCompByDargKey(gamepadHotkey, { height })
  let gap = height/4
  let w = height
  margin[3] = margin[3] - w/2.0 - gap
  margin[1] = margin[1] - w/2.0
  return function() {
    let ac = isGamepad.value
    return ac ? {
      size = SIZE_TO_CONTENT
      gap
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      margin
      watch = [isGamepad]
      children = [
        gamepadBtn
        textComp.__merge({margin = 0}, fontStyle)
        activeKB ? {
            hotkeys = [["^{0}".subst(JB.A),{action=handler}]]
            group
          } : null
      ]
    }
    : textComp.__merge({watch=[isGamepad] margin = src_margin}, fontStyle)
  }
}