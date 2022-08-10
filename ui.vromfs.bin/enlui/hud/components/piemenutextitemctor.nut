from "%enlSqGlob/ui_library.nut" import *

let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")

let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)
let disabledTextColor = Color(50, 50, 50, 50)
let blockedColor = 0xFFFF6060


let mkDisableIcon = @(isBlocked) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  text = fa["times-circle-o"]
  pos = [-hdpx(30), 0]
  color = isBlocked ? blockedColor : disabledTextColor
  fontSize = hdpx(20)
}

local function pieMenuTextItemCtor(text, available = Watched(true), isBlocked = Watched(false)) {
  if (!(text instanceof Watched))
    text = Watched(text)
  return @(curIdx, idx)
    watchElemState(@(sf) {
      watch = [text, available, isBlocked]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text.value
      color = !available.value ? disabledTextColor
        : (sf & S_HOVER) || curIdx.value == idx ? curTextColor
        : defTextColor
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      maxWidth = hdpx(140)
      valign = ALIGN_CENTER

      children = available.value ? null : mkDisableIcon(isBlocked.value)
    })
}

return kwarg(pieMenuTextItemCtor)