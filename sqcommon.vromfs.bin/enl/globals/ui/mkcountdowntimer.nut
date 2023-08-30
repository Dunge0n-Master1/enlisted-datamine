from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { fontSub, fontTiny } = require("%enlSqGlob/ui/fontsStyle.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let {
  smallPadding, accentTitleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")


let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let defTimerSize = hdpxi(13)
let smallTimerSize = hdpxi(12)

let function mkTimer(timestamp, prefixLocId = "", expiredLocId = "timeExpired",
  color = accentTitleTxtColor, prefixColor = defTxtColor, override = {}, isSmall = false
) {
  let prefixTxt = loc(prefixLocId)
  let expiredTxt = loc(expiredLocId)
  let expireSec = Computed(@() max(timestamp - serverTime.value, 0))
  let txtStyle = isSmall ? fontTiny : fontSub
  let timerSize = isSmall ? smallTimerSize : defTimerSize

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
              color = prefixColor
            }.__update(txtStyle)
        hasExpired ? null
          : {
              rendObj = ROBJ_IMAGE
              size = [timerSize, timerSize]
              image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
              color
            }
        {
          rendObj = ROBJ_TEXT
          text = hasExpired ? expiredTxt : secondsToHoursLoc(expireSecVal)
          color
        }.__update(txtStyle)
      ]
    }.__update(override)
  }
}

return kwarg(mkTimer)
