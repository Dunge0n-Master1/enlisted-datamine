from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { h0_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { borderColor } = require("profilePkg.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let {
  bigPadding, smallPadding, defBgColor, idleBgColor, defTxtColor, titleTxtColor, activeBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { endswith } = require("string")
let { mkRankImage, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")
let openRanksInfoWnd = require("%enlist/profile/ranksInfoWnd.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { markSeenRank } = require("%enlist/profile/rankState.nut")


let PORTRAIT_SIZE = hdpx(160)
let NICKFRAME_SIZE = hdpx(140)

let infoiconSize = hdpxi(20)

let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpxi(20)

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

let mkRatingBlock = function(rankDataWatch, hasRankUnseenWatch = Watched(false)) {
  let stateFlag = Watched(0)
  return function() {
    let { rank = 0, rating = 0 } = rankDataWatch.value
    let { locId } = getRankConfig(rank)
    let isUnseen = hasRankUnseenWatch.value
    return {
      flow = FLOW_HORIZONTAL
      watch = [rankDataWatch, hasRankUnseenWatch, stateFlag]
      gap = hdpx(15)
      behavior = Behaviors.Button
      onClick = openRanksInfoWnd
      onHover = function(on) {
        if (isUnseen)
          hoverHoldAction("markSeenRank", rank, @(v) markSeenRank(v))(on)
      }
      onElemState = @(sf) stateFlag(sf)
      children = [
        {
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          children = [
            txt({
              text = loc(locId)
              color = titleTxtColor
            }).__update(h2_txt)
            {
              flow = FLOW_HORIZONTAL
              halign = ALIGN_RIGHT
              size = [flex(), SIZE_TO_CONTENT]
              gap = hdpx(5)
              children = [
                {
                  rendObj = ROBJ_IMAGE
                  size = [infoiconSize, infoiconSize]
                  color = stateFlag.value & S_HOVER ? titleTxtColor : defTxtColor
                  image = Picture($"ui/skin#info/info_icon.svg:{infoiconSize}:{infoiconSize}:K")
                }
                txt({
                  text = loc("rank/playerRank", { rating = rating / 100 })
                  color = stateFlag.value & S_HOVER ? titleTxtColor : defTxtColor
                })
              ]
            }
          ]
        }
        {
          rendObj = ROBJ_SOLID
          padding = hdpx(2)
          halign = ALIGN_RIGHT
          color = stateFlag.value & S_HOVER ? activeBgColor : defBgColor
          children = [
            mkRankImage(rank)
            isUnseen ? smallUnseenNoBlink : null
          ]
        }
      ]
    }
  }
}

return {
  mkPortraitFrame
  mkPortraitIcon
  mkDisabledPortraitIcon

  mkRatingBlock

  mkNickFrame
  mkExpireTime
  PORTRAIT_SIZE
  NICKFRAME_SIZE
}
