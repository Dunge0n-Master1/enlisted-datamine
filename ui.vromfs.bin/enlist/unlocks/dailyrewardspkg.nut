from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { isBooster } = require("%enlist/soldiers/model/boosters.nut")
let {
  mkRewardIcon, mkRewardImages, rewardWidthToHeight
} = require("%enlist/battlepass/rewardsPkg.nut")
let {
  defBgColor, bigPadding, smallPadding, activeTxtColor, titleTxtColor,
  accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  mkXpBooster, mkBoosterInfo, mkBoosterLimits
} = require("%enlist/components/mkXpBooster.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkItemRow, itemsSort } = require("%enlist/items/crateInfo.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")


let sizeCard = [hdpx(180), hdpx(200)]
let sizeIcon = hdpx(35)
let imageHeight = hdpx(180)
let imageSize = [(rewardWidthToHeight * imageHeight).tointeger(), imageHeight]
let trigger = "rewardAnim"
let wndPadding = sh(1)
let rewardWidth = hdpxi(160)

let wndParams = {
  bgColor = Color(11, 11, 19)
  baseColor  = Color(112, 112, 112)
  activeColor  = Color(219, 219, 219)
  rewardColor  = accentTitleTxtColor
}

let cardBottom = @(count, cardIcon){
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  margin = bigPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  children = [
    {
      rendObj = ROBJ_TEXT
      padding = [0, smallPadding]
      text = count > 99 ? count : loc("common/amountShort", { count = count })
      color = activeTxtColor
    }.__update(fontBody)
    cardIcon
  ]
}


let mkRewardCardByTemplate = @(itemTemplate, allItemTemplates, commonArmy)
  itemTemplate != null
    ? function() {
      let allTemplates = allItemTemplates.value
      let commonArmyId = commonArmy.value
      let template = allTemplates?[commonArmyId][itemTemplate]
      let res = {
        watch = [allItemTemplates, commonArmy]
      }
      return isBooster(template)
        ? res.__update({
            size = sizeCard
            padding = smallPadding
            children = [
              mkXpBooster(template)
              mkBoosterInfo(template, fontBody.__merge({ color = titleTxtColor }))
              mkBoosterLimits(template, fontBody.__merge({ color = titleTxtColor }))
            ]
          })
        : res
    }
  : null

let function mkRewardCardByPresentation(presentation, count, allItemTemplates, commonArmy) {
  let itemTpl = presentation.itemTemplate
  let template = allItemTemplates.value?[commonArmy.value][itemTpl]
  if (isBooster(template))
    return mkRewardCardByTemplate(itemTpl, allItemTemplates, commonArmy)

  let cardIcon = mkRewardIcon(presentation, sizeIcon, { vplace = ALIGN_CENTER })
  let cardImages = mkRewardImages(presentation, imageSize, {
    hplace = ALIGN_CENTER
    pos = [0, smallPadding]
  })
  return {
    size = sizeCard
    rendObj = ROBJ_SOLID
    color = defBgColor
    children = [
      cardImages
      count > 0 ? cardBottom(count, cardIcon) : null
    ]
  }
}

let mkBoosterItemRow = @(itemTemplate, tpl, armyId, count) {
  flow = FLOW_HORIZONTAL
  children = [
    txt({
      minWidth = hdpx(32)
      text = $"x{count}"
      color = wndParams.rewardColor
    }).__update(fontSub)
    mkItemRow(mkShopItem(itemTemplate, tpl, armyId))
  ]
}

let mkTextArea = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  text
  color = activeTxtColor
}.__update(fontSub)

let boosterTopHint = mkTextArea(loc("boosterTooltipHeader"))
let boosterBottomHint = mkTextArea(loc("boosterTooltipHint"))

let mkBoosterItemsView = @(boostersItems, armyId, allTemplates, commonArmy)
  function() {
    let templates = allTemplates.value
    let armyTemplates = templates?[armyId]
    let commonTemplates = templates?[commonArmy.value]

    boostersItems = boostersItems.map(@(pack)
      pack.map(@(item) item.__merge({
        tpl = armyTemplates?[item.itemTemplate] ?? commonTemplates?[item.itemTemplate]
      }))
      .sort(itemsSort)
    )
    let packsIds = ["reinforcing", "instant"]
    return {
      watch = [commonArmy, allTemplates]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [boosterTopHint]
        .extend(packsIds.map(function(packId) {
          let pack = boostersItems?[packId] ?? []
          return pack.len() == 0 ? null
            : {
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_VERTICAL
                children = pack.map(function(item) {
                  let { itemTemplate, count} = item
                  let tpl = armyTemplates?[itemTemplate] ?? commonTemplates?[itemTemplate]
                  return tpl == null ? null : mkBoosterItemRow(itemTemplate, tpl, armyId, count)
                })
              }
        }))
        .append(boosterBottomHint)
    }
  }


let mkMoveDownAnim = @(delay = 0) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, delay }
  { prop = AnimProp.translate, from = [0, -sh(15)], to = [0,0], duration = 0.5,
    play = true, easing = OutQuart, delay }
]

let mkAppearAnim = @(delay = 0, onFinish = null, soundName = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true, trigger }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true,
    easing = InOutCubic, delay = delay, trigger, sound = { stop = soundName }}
  { prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.6, play = true,
    easing = InOutCubic, delay = delay, trigger }
  { prop = AnimProp.translate, from = [0, -sh(15)], to = [0,0], duration = 0.6,
    play = true, easing = OutQuart, delay = delay, trigger, onFinish }
]

let ROLL_DURATION = 2.5

let mkRollAnim = @(delay, yPos, onEnter = null, onFinish = null, soundName = null) [
  { prop = AnimProp.translate, from = [0,yPos], to = [0,yPos], duration = delay,
    play = true, trigger, onEnter }
  { prop = AnimProp.translate, from = [0,yPos], to = [0,hdpx(50)], duration = ROLL_DURATION,
    play = true, delay = delay, trigger, sound = { stop = soundName }}
  { prop = AnimProp.translate, from = [0,hdpx(50)], to = [0,0], duration = 0.2,
    play = true, delay = delay + ROLL_DURATION - 0.05, trigger, onFinish }
]

let mkGrayBox = @(w) {
  rendObj = ROBJ_BOX
  fillColor = 0xFF404040
  borderColor = 0xFF606060
  borderWidth = hdpx(1)
  size = [hdpx(w), flex()]
}

let mkGrayArrow = @(x, y, w, h) {
  pos = [hdpx(x), hdpx(y)]
  rendObj = ROBJ_IMAGE
  size = [hdpxi(w), hdpxi(h)]
  image = Picture("!ui/skin#rewards/arrow_rewards.svg:{0}:{1}:K".subst(hdpxi(w), hdpxi(h)))
}

let bigRewardSeparatorBoxes = {
  padding = [wndPadding / 2, 0]
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  size = [hdpx(10), rewardWidth]
  children = [
    mkGrayBox(4)
    mkGrayBox(6)
  ]
}

let bigRewardSeparatorArrows = {
  size = [hdpx(10), hdpx(40)]
  children = [
    mkGrayArrow(-6, 0, 19, 40)
    mkGrayArrow(2, 0, 19, 40)
  ]
}

return {
  wndParams
  sizeCard
  mkRewardCardByPresentation
  mkRewardCardByTemplate
  mkBoosterItemsView
  mkMoveDownAnim
  mkAppearAnim
  mkRollAnim
  animTrigger = trigger
  bigRewardSeparatorBoxes
  bigRewardSeparatorArrows
  rewardWidth
}
