from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let { defTxtColor, activeTxtColor, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")


let textColor = @(sf) sf & S_ACTIVE ? 0xFFFFFFFF
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let mkTextCtor = @(text) @(sf) {
  rendObj = ROBJ_TEXT
  size = [flex(), SIZE_TO_CONTENT]
  text
  color = textColor(sf)
}.__update(fontSub)

let function mkToggleHeader(isShow, textOrCtor) {
  let textCtor = type(textOrCtor) == "string" ? mkTextCtor(textOrCtor) : textOrCtor
  return watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [bigPadding, 0, 0, 0]
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    onClick = @() isShow(!isShow.value)
    children = [
      textCtor(sf)
      @() faComp(isShow.value ? "minus-square" : "plus-square", {
        watch = isShow
        size = [hdpx(25), hdpx(25)]
        hplace = ALIGN_CENTER
        fontSize = hdpx(20)
        color = textColor(sf)
      })
    ]
  })
}

return mkToggleHeader