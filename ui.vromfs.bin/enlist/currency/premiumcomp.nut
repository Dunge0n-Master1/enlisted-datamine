from "%enlSqGlob/ui_library.nut" import *

let colorize = require("%ui/components/colorize.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { premiumActiveTime, hasPremium } = require("premium.nut")
let {
  hasPremiumColor, defTxtColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { colFull } = require("%enlSqGlob/ui/designConst.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let premiumBtnSize = colFull(1)

let premiumImagePath = @(size) (isNewDesign.value
    ? "!ui/uiskin/premium/icon_prem.svg:{0}:{0}:K"
    : "!ui/uiskin/currency/enlisted_prem.svg:{0}:{0}:K")
    .subst(size.tointeger())

let premiumImage = @(size, override = {}) @() {
  watch = hasPremium
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(premiumImagePath(size))
  color = hasPremium.value ? Color(255,255,255) : Color(120,120,120)
}.__update(override)


let premiumActiveInfo = @(customStyle = {}, premColor = hasPremiumColor)
  function() {
    let activeTime = premiumActiveTime.value
    return txt({
      watch = premiumActiveTime
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = activeTime > 0 ? activeTxtColor : defTxtColor
      text = " {status} {left}".subst({
        status = utf8ToUpper(loc(activeTime > 0
          ? "premium/activated"
          : "premium/notActivated"))
        left = activeTime > 0
          ? loc("premium/activatedLeft", {
              timeInfo = colorize(premColor, secondsToHoursLoc(activeTime))
            })
          : ""
      })
    }).__update(customStyle)
  }


let premiumBg = @(size) Picture("!ui/uiskin/premium/prem_bg.svg:{0}:{0}:K".subst(size))

return {
  premiumImage
  premiumActiveInfo
  premiumBtnSize
  premiumBg
}
