from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let {
  boosterItems, allBoosters
} = require("%enlist/soldiers/model/boosters.nut")
let {
  disabledTxtColor, smallPadding, smallOffset, blurBgFillColor, accentColor, darkBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  mkXpBooster, boosterWidthToHeight, mkBoosterExpireInfo
} = require("%enlist/components/mkXpBooster.nut")
let { rewardBgSizePx } = require("%enlist/items/itemsPresentation.nut")

let bImgHeight = rewardBgSizePx[1]
let bImgSize = [(boosterWidthToHeight * bImgHeight).tointeger(), bImgHeight]

let emptyBoostersText = txt({
  text = loc("profile/boostersIsEmpty")
  hplace = ALIGN_CENTER
  color = disabledTxtColor
}).__update(h2_txt)

let function mkBooster(boosterBase) {
  let { campaignLimit } = boosterBase
  let limitText = campaignLimit.len() == 0 ? loc("allCampaigns")
    : ", ".join(campaignLimit.map(@(c) loc(c.title)))
  return {
    rendObj = ROBJ_SOLID
    xmbNode = XmbNode()
    behavior = Behaviors.Button
    size = [hdpx(400), hdpx(170)]
    margin = [0, 0, 0, hdpx(110)]
    flow = FLOW_VERTICAL
    color = blurBgFillColor
    children = [
      {
        rendObj = ROBJ_SOLID
        size = flex()
        color = darkBgColor
        padding = [0, 0, hdpx(5), hdpx(110)]
        children = mkBoosterExpireInfo(boosterBase,
          true,
          {
            margin = [0, smallOffset]
            flow = FLOW_HORIZONTAL
          }
        )
      }
      {
        children = [
          {
            size = bImgSize
            pos = [-hdpx(90), -hdpx(40)]
            children = mkXpBooster(boosterBase, {size = [hdpx(170),hdpx(200)]})
          }
          {
            flow = FLOW_VERTICAL
            padding = [0, 0, 0, hdpx(110)]
            children = [
              txt({
                text = limitText
                margin = [hdpx(7), 0]
              }).__update(sub_txt)
              txt(loc($"booster/expBonus/{boosterBase.bType}")).__update(sub_txt)
              txt({
                text = loc("booster/expBonus", {exp = (boosterBase.expMul * 100).tostring()})
                color = accentColor
                margin = [hdpx(14), 0]
              }).__update(h2_txt)
              txt({
                padding = [0, 0, hdpx(20), 0]
                text = loc($"booster/type/{boosterBase.bType}")
              }).__update(sub_txt)
            ]
          }
        ]
      }
    ]
  }
}

let boostersListUi = function() {
  let components = allBoosters.value.map(@(boosterBase)
    mkBooster(boosterBase))

  let boostersList = wrap(components, {
    width = sh(100)
    vGap = hdpx(75)
  })
  let scrollBoostersList = makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      padding = [hdpx(40), 0]
      xmbNode = XmbContainer({
        canFocus = @() false
        scrollSpeed = 5
        isViewport = true
      })
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = boostersList
    },
    { styling = thinStyle }
  )

  return {
    rendObj = ROBJ_BOX
    watch = [boosterItems, allBoosters]
    size = flex()
    valign = components.len() ? ALIGN_TOP : ALIGN_CENTER
    padding = smallPadding
    children = components.len() ? scrollBoostersList : emptyBoostersText
  }
}

return {
  size = flex()
  children = boostersListUi
}
