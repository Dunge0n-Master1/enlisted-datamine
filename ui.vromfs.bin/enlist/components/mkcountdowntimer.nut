from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let {
  smallPadding, accentTitleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")


let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpx(18).tointeger()

let function mkTimer(timestamp, prefixLocId = "", expiredLocId = "timeExpired", override = {}) {
  let prefixTxt = loc(prefixLocId)
  let expiredTxt = loc(expiredLocId)
  let expireSec = Computed(@() max(timestamp - serverTime.value, 0))

  return function() {
    let expireSecVal = expireSec.value
    let hasExpired = expireSecVal <= 0

    return {
      watch = expireSec
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        hasExpired || prefixTxt == "" ? null
          : {
              rendObj = ROBJ_TEXT
              text = prefixTxt
              color = defTxtColor
            }.__update(sub_txt)
        hasExpired ? null
          : {
              rendObj = ROBJ_IMAGE
              size = [timerSize, timerSize]
              image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
              color = accentTitleTxtColor
            }
        {
          rendObj = ROBJ_TEXT
          text = hasExpired ? expiredTxt : secondsToHoursLoc(expireSecVal)
          color = accentTitleTxtColor
        }.__update(sub_txt)
      ]
    }.__update(override)
  }
}

return kwarg(mkTimer)
