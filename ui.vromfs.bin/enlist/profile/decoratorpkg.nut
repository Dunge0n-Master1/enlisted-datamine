from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { h0_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { borderColor } = require("profilePkg.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { bigPadding, smallPadding, defBgColor, idleBgColor, defTxtColor,
  titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { endswith } = require("string")

let PORTRAIT_SIZE = hdpx(160)
let NICKFRAME_SIZE = hdpx(140)

let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpx(20).tointeger()

let mkImage = @(path, size, override = {}) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  imageValign = ALIGN_TOP
  image = Picture(endswith(path, ".svg") ? $"!{path}:{size}:{size}:K" : $"{path}?Ac")
}.__update(override)

let function mkExpireTime(expireTime, override = {}) {
  let expireText = Computed(function() {
    let expireSec = expireTime - serverTime.value
    return expireSec <= 0 ? loc("timeExpired") : secondsToHoursLoc(expireSec)
  })
  return @() {
    watch = expireText
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    padding = bigPadding
    margin = hdpx(2)
    halign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [timerSize, timerSize]
        image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
      }
      txt({
        text = expireText.value
        color = titleTxtColor
      })
    ]
  }.__update(override)
}

let function mkPortraitIcon(portraitCfg, pSize = PORTRAIT_SIZE) {
  let { bgimg = "", icon = "", color = Color(255,255,255) } = portraitCfg
  let size = (pSize - smallPadding * 2).tointeger()
  return {
    padding = smallPadding
    children = [
      bgimg == "" ? null : mkImage(bgimg, size)
      icon == "" ? null : mkImage(icon, size, { color })
    ]
  }
}

let disabledParams = {
  tint = Color(40, 40, 40, 180)
  picSaturate = 0.0
}

let function mkDisabledPortraitIcon(portraitCfg) {
  let { bgimg = "", icon = "" } = portraitCfg
  let size = (PORTRAIT_SIZE - smallPadding * 2).tointeger()
  return {
    padding = smallPadding
    children = [
      bgimg != "" ? mkImage(bgimg, size, disabledParams) : null
      icon != "" ? mkImage(icon, size, disabledParams) : null
    ]
  }
}

let mkPortraitFrame = @(children, onClick = null, onHover = null, addObject = null)
  watchElemState(function(sf) {
    if (addObject != null)
      children.append(addObject?(sf))
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = [PORTRAIT_SIZE, PORTRAIT_SIZE]
      fillColor = defBgColor
      borderColor = borderColor(sf)
      behavior = Behaviors.Button
      onClick
      onHover
      children
    }
  })

let mkNickFrame = @(nCfg, color = defTxtColor, borderColor = idleBgColor) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = [NICKFRAME_SIZE, NICKFRAME_SIZE]
  fillColor = defBgColor
  borderColor
  children = txt({
    text = nCfg?.framedNickName("") ?? ""
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color
  }).__update(h0_txt)
}

return {
  mkPortraitFrame
  mkPortraitIcon
  mkDisabledPortraitIcon

  mkNickFrame
  mkExpireTime
  PORTRAIT_SIZE
  NICKFRAME_SIZE
}
