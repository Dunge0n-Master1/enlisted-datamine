from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { smallPadding, bigPadding, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")


//bg size = 170x210
let boosterWidthToHeight = 170.0 / 210.0
let typeImgPW = 100.0 * 100 / 170
let typeImgPH = 100.0 * 100 / 210
let typeImgOffsetPH = 100.0 * 14 / 210

let defOverride = { color = defTxtColor }.__update(sub_txt)

let imgByBtype = {
  ["global"]   = "ui/skin#/battlepass/boost_global.avif"
  army         = "ui/skin#/battlepass/boost_army.avif"
  squad        = "ui/skin#/battlepass/boost_squad.avif"
  soldier      = "ui/skin#/battlepass/boost_soldier.avif"
}
let imgUnknown = "ui/skin#/battlepass/random.avif"
let durationIconSize = hdpxi(20)

let durationBoosterBlock = txt({
  text = loc("booster/duration")
  margin = [0, hdpx(35), 0, 0]
}).__update(sub_txt)

let function mkDurationInfo(icon, text, override = {}) {
  let color  = override?.color ?? defTxtColor
  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        size = [durationIconSize, durationIconSize]
        rendObj = ROBJ_IMAGE
        color
        image = Picture($"{icon}:{durationIconSize}:{durationIconSize}:K")
      }
      {
        rendObj = ROBJ_TEXT
        text
      }.__update(sub_txt, override)
    ]
  }
}

let mkXpBooster = function(booster, override = {}) {
  let { bType = null } = booster
  return {
    rendObj = ROBJ_IMAGE
    size = flex()
    margin = bigPadding
    image = Picture("ui/skin#/battlepass/bg_boost.avif")
    children = {
      size = [pw(typeImgPW), ph(typeImgPH)]
      pos = [0, ph(typeImgOffsetPH)]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture(imgByBtype?[bType] ?? imgUnknown)
    }
  }.__update(override)
}

let function mkBoosterInfo(booster, override = sub_txt) {
  let { expMul = 0 } = booster
  return expMul <= 0 ? null
    : {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        text = $"+{100 * expMul}%"
      }.__update(override)
}

let boostTimeIcon = "ui/skin#/battlepass/boost_time.svg"
let boostBattlesIcon = "ui/skin#/battlepass/boost_battles.svg"

let mkBoosterLeftBattles = @(battles, override)
  mkDurationInfo(boostBattlesIcon, battles, override)

let mkLimitsChildren = @(battles, lifeTime, hasDurationLabel, override) [
  battles == 0 ? null
    : mkBoosterLeftBattles(battles, override)
  hasDurationLabel && battles > 0
    ? durationBoosterBlock
    : null
  lifeTime == 0 ? null
    : mkDurationInfo(boostTimeIcon, secondsToHoursLoc(lifeTime), override)
]

let function mkBoosterExpireInfo(booster, hasDurationLabel = false, cStyle = {}, override = defOverride) {
  let { leftBattles = 0, lifeTime = 0, expireTime = 0 } = booster
  let res = {
    flow = FLOW_VERTICAL
    gap = smallPadding
    vplace = ALIGN_BOTTOM
  }.__update(cStyle)

  if (lifeTime == 0)
    return res.__update({
      children = mkBoosterLeftBattles(leftBattles, override)
    })

  return @() res.__update({
    watch = serverTime
    children = mkLimitsChildren(leftBattles, expireTime - serverTime.value, hasDurationLabel, override)
  })
}

let function mkBoosterLimits(booster, override = defOverride) {
  let { battles = 0, lifeTime = 0 } = booster
  return {
    flow = FLOW_VERTICAL
    gap = smallPadding
    vplace = ALIGN_BOTTOM
    children = mkLimitsChildren(battles, lifeTime, false, override)
  }
}

return {
  boosterWidthToHeight
  mkXpBooster
  mkBoosterInfo
  mkBoosterExpireInfo
  mkBoosterLimits
}
