from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { TextActive, TextHighlight, TextDefault } = require("%ui/style/colors.nut")
let { buttonSound } = require("%ui/style/sounds.nut")
let getGamepadHotkeys = require("%ui/components/getGamepadHotkeys.nut")
let gamepadImgByKey = require("%ui/components/gamepadImgByKey.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")

let defIconColor = @(sf) sf & S_ACTIVE ? TextActive
  : sf & S_HOVER ? TextHighlight
  : TextDefault

let function fontIconButton(icon, params = null) {
  let stateFlags = params?.stateFlags ?? Watched(0)
  let gamepadHotkey = getGamepadHotkeys(params?.hotkeys, true)
  let { skipDirPadNav = (gamepadHotkey ?? "") != "" } = params
  let img = (gamepadHotkey == "") ? null : gamepadImgByKey.mkImageCompByDargKey(gamepadHotkey)
  local { watch = [] } = params
  watch = (typeof watch == "array" ? clone watch : [watch]).append(stateFlags, isGamepad)
  return function() {
    let sfVal = stateFlags.value
    let gamepadImg = isGamepad.value && img!=null
    let p = (params ?? {}).__merge({ watch, skipDirPadNav })
    if (p?.byStateFlags)
      p.__update(p.byStateFlags(sfVal))
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER

      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags.update(sf & ~S_TOP_HOVER)
      children = gamepadImg ? img : faComp(icon, {
        fontSize = hdpx(20)
        color = params?.iconColor(sfVal) ?? defIconColor(sfVal)
      }.__update(params?.iconParams ?? {}))

      sound = buttonSound
    }.__merge(p)
  }
}

return fontIconButton
