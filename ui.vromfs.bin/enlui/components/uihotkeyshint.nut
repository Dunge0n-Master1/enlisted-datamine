from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let formatInputBinding = require("%ui/control/formatInputBinding.nut")
let parseDargHotkeys =  require("%ui/components/parseDargHotkeys.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let {HUD_TIPS_HOTKEY_FG} = require("%ui/hud/style.nut")

let function mkHintRow(hotkeys, params={}) {
  let textFunc = params?.textFunc ??@(text) {
    rendObj = ROBJ_TEXT
    text
    color = HUD_TIPS_HOTKEY_FG
    font = params?.font ?? sub_txt.font
    fontSize = params?.fontSize ?? sub_txt.fontSize
  }
  let noWatchGamepad = params?.column != null
  return function(){
    let res = { watch = noWatchGamepad ? null : isGamepad }
    let isGamepadV = noWatchGamepad ? params.column == 1 : isGamepad.value
    let rowTexts = parseDargHotkeys(hotkeys)?[isGamepadV ? "gamepad" : "kbd"] ?? []
    if (rowTexts.len() == 0)
      return res
    return res.__update({
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      vplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = formatInputBinding.buildElems(rowTexts, { textFunc })
    }, params)
  }
}
let function mkHotkey(hotkey, action, params={}){
  return {
    children = mkHintRow(hotkey, params)
    hotkeys = [[hotkey, {action=action, description={skip=true}}]]
  }.__merge(params)
}

return {
  mkHintRow
  mkHotkey
}