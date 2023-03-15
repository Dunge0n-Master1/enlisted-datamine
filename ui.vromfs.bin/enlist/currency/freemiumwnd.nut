from "%enlSqGlob/ui_library.nut" import *

let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { h1_txt, h2_txt, body_txt, h1_bold_txt, fontawesome, sub_txt, h2_bold_txt
} = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { bigPadding, commonBtnHeight, soldierLockedLvlColor, activeTxtColor,
  blurBgFillColor, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { CAMPAIGN_NONE, curCampaignAccessItem,
  freemiumExpBoost, upgradeSoldiers, campPresentation, showCampaignGroup
} = require("%enlist/campaigns/campaignConfig.nut")
let { uType, allArmyUnlocks } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { mkHeaderFlag, primeFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { weapInfoBtn } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let { openUnlockSquadScene } = require("%enlist/soldiers/unlockSquadScene.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { normal } = require("%ui/style/cursors.nut")
let { allItemTemplates, findItemTemplate } = require("%enlist/soldiers/model/all_items_templates.nut")
let { decoratorsPresentation } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { mkPortraitIcon, mkNickFrame, NICKFRAME_SIZE
} = require("%enlist/profile/decoratorPkg.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")


const WND_UID = "freemiumWindow"
let WND_WIDTH = fsh(120)
let ANIM_DELAY = 0.1
let ANIM_TIME = 0.3
let BLINK_DELAY = 0.2
let BONUSES_TEXT_DELAY = 2.0

const bgColor = 0xFF0B0B13
const baseColor = 0xFF707070
const activeColor = 0xFFDBDBDB

let showAnimation = Watched(true)

let hasCampLockedSquads = Computed(@() allArmyUnlocks.value.findindex(function(unlock) {
  let { unlockType, campaignGroup = CAMPAIGN_NONE } = unlock
  return unlockType == uType.SQUAD && campaignGroup != CAMPAIGN_NONE
}) != null)

let mkImage = @(path, customStyle = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(customStyle)

let close = @() removeModalWindow(WND_UID)

let mkValAnimColor = @(delay, c1, c2) !showAnimation.value ? [] : [
  { prop = AnimProp.color, from = c1, to = c2, duration = 0.75,
    play = true, delay }
  { prop = AnimProp.color, from = c2, to = c2, duration = 0.15,
    play = true, delay = delay + 0.7 }
  { prop = AnimProp.color, from = c2, to = c1, duration = 0.55,
    play = true, delay = delay + 0.8 }
]

let mkValAnimScale = @(delay) !showAnimation.value ? [] : [
  { prop = AnimProp.scale, from = [1,1], to = [1.1,1.1], duration = 0.25,
    play = true, delay }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1.1,1.1], duration = 0.35,
    play = true, delay = delay + 0.2 }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1,1], duration = 0.45,
    play = true, delay = delay + 0.5 }
]

let mkIconBar = @(count, color, fName) {
  rendObj = ROBJ_INSCRIPTION
  animations = mkValAnimColor(BLINK_DELAY * 2 + BONUSES_TEXT_DELAY, color, activeColor)
  validateStaticText = false
  text = "".join(array(count, fa[fName]))
  font = fontawesome.font
  fontSize = hdpx(30)
  color
}

let function freemiumBlockHeader() {
  let { color = null, darkColor = null, locBase = "" } = campPresentation.value
  return {
    watch = campPresentation
    flow = FLOW_HORIZONTAL
    gap = hdpx(330)
    children = [
      {
        flow = FLOW_VERTICAL
        children = [
          mkHeaderFlag({
              rendObj = ROBJ_TEXT
              text = loc($"{locBase}/title")
              padding = [fsh(2), fsh(3)]
            }.__update(h1_txt),
            {
              flagColor = color
              offsetColor = darkColor
              tailColor = 0x00000000
            })
          txt({
            text = loc($"freemium/bothSide")
            padding = [hdpx(15), hdpx(30)]
            color = activeTxtColor
          }.__update(h2_txt))
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        children = {
          text = loc($"{locBase}/desc", "")
          vplace = ALIGN_BOTTOM
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          maxWidth = hdpx(420)
        }
      }
    ]
  }
}

let mkDescAnim = @(delay) !showAnimation.value ? {} : {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay + 0.05,
      play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = ANIM_TIME,
      delay, play = true, easing = OutQuad }
    { prop = AnimProp.translate, from = [0, -hdpx(150)], to = [0, 0],
      duration = ANIM_TIME, delay, play = true, easing = OutQuad,
      onFinish = @() showAnimation(false) }
  ]
}

let mkInfoTitle = @(idx, unitVal, unitDesc = null) function() {
  let { color = null } = campPresentation.value
  return {
    flow = FLOW_HORIZONTAL
    children = [
      txt({
        text = unitVal
        color
        transform = {}
        animations = [].extend(
          mkValAnimColor(BLINK_DELAY * idx + BONUSES_TEXT_DELAY, color, activeColor),
          mkValAnimScale(BLINK_DELAY * idx + BONUSES_TEXT_DELAY)
        )
      }.__update(unitDesc ? h1_bold_txt : h2_bold_txt))
      unitDesc == null ? null
        : {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = unitDesc
            maxWidth = hdpx(100)
            color = activeTxtColor
            margin = [0, bigPadding]
          }.__update(sub_txt)
    ]
  }
}

let mkInfoStars = @(idx, stars) function() {
  let { color = null } = campPresentation.value
  return {
    watch = campPresentation
    flow = FLOW_HORIZONTAL
    animations = mkValAnimScale(BLINK_DELAY * idx + BONUSES_TEXT_DELAY)
    transform = {}
    children = [
      mkIconBar(stars, color, "star"),
      stars < 5 ? mkIconBar(5 - stars, soldierLockedLvlColor, "star-o") : null
    ]
  }
}

let mkDesc = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  maxWidth = hdpx(350)
  margin = [hdpx(20), 0]
  text
  color = activeColor
}.__update(sub_txt)

let function mkInfoBlock(idx, titleBlock, descText, addObj = null) {
  if (typeof descText != "array")
    descText = [descText]
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = fsh(2)
    children = [titleBlock].extend(descText.map(mkDesc)).append(addObj)
  }.__update(mkDescAnim(ANIM_DELAY * idx))
}


let function advantagesBlock() {
  local idx = 0
  let children = []
  let { locBase = "" } = campPresentation.value

  if (freemiumExpBoost.value > 0) {
    children.append(mkInfoBlock(idx,
      mkInfoTitle(idx, $"x{freemiumExpBoost.value + 1}", loc("freemium/expBonusDesc")),
      loc("freemium/discountDesc")))
    ++idx
  }

  local level = upgradeSoldiers.value
  if (level != 0) {
    if (level < 0)
      level += 5
    children.append(mkInfoBlock(idx,
      mkInfoStars(idx, level),
      loc($"{locBase}/levelSquads")))
    ++idx
  }

  children.append(mkInfoBlock(idx,
    mkInfoTitle(idx, loc("freemium/anyTimeBuy")),
    loc("freemium/anyTimeBuyDesc")))
  ++idx

  if (hasCampLockedSquads.value) {
    children.append(mkInfoBlock(idx,
      mkInfoTitle(idx, loc("freemium/new")),
      loc("freemium/newDesc")))
    ++idx
  }

  let { decorators = [] } = curCampaignAccessItem.value
  if (decorators.len() > 0) {
    let decoratorsChildren = []
    foreach (decorator in decorators) {
      let { guid } = decorator
      let { portrait = {}, nickFrame = {} } = decoratorsPresentation
      if (guid in portrait)
        decoratorsChildren.append(mkPortraitIcon(portrait[guid], NICKFRAME_SIZE))
      else if (guid in nickFrame)
        decoratorsChildren.append(mkNickFrame(nickFrame[guid]))
    }
    if (decoratorsChildren.len() > 0)
      children.append(mkInfoBlock(idx,
        mkInfoTitle(idx, utf8ToUpper(loc("vehDecoratorHeader"))), [], {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          margin = [bigPadding,0,0,0]
          gap = bigPadding
          children = decoratorsChildren
        }
      ))
  }

  return {
    watch = [campPresentation, freemiumExpBoost, upgradeSoldiers,
      hasCampLockedSquads, curCampaignAccessItem]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = {
      rendObj = ROBJ_SOLID
      size = [hdpx(1), flex()]
      color = baseColor
      margin = bigPadding
    }
    children
  }
}

let function onPurchase(shopItem) {
  buyShopItem({
    shopItem
    productView = {
      flow = FLOW_VERTICAL
      margin = [0,0,fsh(3),0]
      halign = ALIGN_CENTER
      children = freemiumBlockHeader
    }
  })
  sendBigQueryUIEvent("action_buy_freemium", "freemium_promo")
}

let function purchaseButton() {
  let res = { watch = [curCampaignAccessItem, campPresentation] }
  if (curCampaignAccessItem.value == null)
    return res

  let { color = null } = campPresentation.value
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    children = Flat(loc("freemium/getPack"), @() onPurchase(curCampaignAccessItem.value), {
      size = [SIZE_TO_CONTENT, commonBtnHeight]
      hplace = ALIGN_RIGHT
      margin = 0
      hotkeys = [ ["^J:Y", {description={ skip=true } sound="click"}] ]
      style = {
        BgNormal = color
        TextNormal = 0xFFFFFFFF
      }
    })
  })
}

let function mkDiscountInfo(discountInPercent, endTime) {
  return {
    flow = FLOW_HORIZONTAL
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    children = [
      mkHeaderFlag({
        size = [SIZE_TO_CONTENT, hdpx(48)]
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        padding = [0, fsh(5), 0, fsh(1)]
        children = [
          txt({
            text = utf8ToUpper(loc("shop/discountNotify"))
            color = titleTxtColor
          }.__update(sub_txt))
          endTime == 0 ? null : mkCountdownTimer({ timestamp = endTime })
        ]
      }, primeFlagStyle.__merge({
        size = SIZE_TO_CONTENT
        offset = 0
        flagColor = 0xFF007800
      }))
      mkDiscountWidget(discountInPercent)
    ]
  }
}

let function purchaseBlock() {
  let res = { watch = [curCampaignAccessItem] }
  if (curCampaignAccessItem.value == null)
    return res

  let { discountIntervalTs = [], discountInPercent = 0 } = curCampaignAccessItem.value
  let [ beginTime = 0, endTime = 0 ] = discountIntervalTs
  let isDiscountActive = beginTime > 0
    && beginTime <= serverTime.value
    && (serverTime.value <= endTime || endTime == 0)

  return {
    watch = [curCampaignAccessItem, serverTime]
    flow = FLOW_VERTICAL
    size = [SIZE_TO_CONTENT, commonBtnHeight * 2]
    children = [
      purchaseButton
      !isDiscountActive ? null : mkDiscountInfo(discountInPercent, endTime)
    ]
  }
}

let function mkVehicleSquad(squadData) {
  let { startVehicle } = squadData
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      watchElemState(@(sf) {
        rendObj = ROBJ_SOLID
        color = blurBgFillColor
        margin = [hdpx(40), 0, hdpx(10), 0]
        behavior = Behaviors.Button
        onClick = function() {
          close()
          openUnlockSquadScene(squadData, KWARG_NON_STRICT)
        }
        children = [
          iconByGameTemplate(startVehicle, { width = hdpx(200), height = hdpx(90) })
          weapInfoBtn(sf)
        ]
      })
      txt(getItemName(startVehicle)).__update(body_txt)
    ]
  }
}

let function vehiclesBlock(squads) {
  squads = squads
    .map(function(squad) {
      let squadCfg = squadsCfgById.value?[squad.armyId][squad.id] ?? {}
      return squad.__merge(squadCfg, {
        armyId = squad.armyId
        squadCfg
        unlockInfo = { hasTestDrive = true }
      })
    })
    .filter(@(squad) squad?.startVehicle != null)
  if (squads.len() == 0)
    return null

  return function() {
    let { color = null } = campPresentation.value
    return {
      watch = [squadsCfgById, campPresentation]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = fsh(2)
      children = [
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = txt({
            text = "+"
            fontSize = fsh(8)
            margin = [0, hdpx(15)]
            color
          })
          children = squads.map(mkVehicleSquad)
        }
        {
          rendObj = ROBJ_TEXTAREA
          text = loc("freemium/giftTank")
          color
          behavior = Behaviors.TextArea
          maxWidth = hdpx(340)
        }.__update(h2_bold_txt)
      ]
    }
  }
}

let function mkArmSquad(squadData) {
  let { gametemplate } = squadData
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      watchElemState(@(sf) {
        rendObj = ROBJ_SOLID
        color = blurBgFillColor
        margin = [hdpx(40), 0, hdpx(10), 0]
        behavior = Behaviors.Button
        onClick = function() {
          close()
          openUnlockSquadScene(squadData, KWARG_NON_STRICT)
        }
        children = [
          iconByGameTemplate(gametemplate, { width = hdpx(200), height = hdpx(90) })
          weapInfoBtn(sf)
        ]
      })
      txt(getItemName(gametemplate)).__update(sub_txt)
    ]
  }
}

let function armsBlock(squads) {
  squads = squads
    .map(function(squad) {
      let squadCfg = squadsCfgById.value?[squad.armyId][squad.id] ?? {}
      return squad.__merge(squadCfg, {
        armyId = squad.armyId
        squadCfg
        unlockInfo = { hasTestDrive = true }
      })
    })
    .filter(@(squad) (squad?.startVehicle ?? "") == "" && (squad?.newWeapon.len() ?? 0) > 0)
    .map(function(squad) {
      let item = findItemTemplate(allItemTemplates, squad.armyId, squad.newWeapon[0])
      squad.gametemplate <- item.gametemplate
      return squad
    })
  if (squads.len() == 0)
    return null

  return function() {
    let { color = null } = campPresentation.value
    return {
      watch = [allItemTemplates, squadsCfgById, campPresentation]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = fsh(2)
      children = [
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = txt({
            text = "+"
            fontSize = fsh(8)
            margin = [0, hdpx(15)]
            color
          })
          children = squads.map(mkArmSquad)
        }
        {
          rendObj = ROBJ_TEXTAREA
          text = loc("freemium/giftMarines")
          color
          behavior = Behaviors.TextArea
          maxWidth = hdpx(340)
        }.__update(h2_bold_txt)
      ]
    }
  }
}

let function squadsBlock() {
  let res = { watch = curCampaignAccessItem }
  local { squads = null } = curCampaignAccessItem.value
  if (squads == null)
    return res

  return res.__update({
    watch = curCampaignAccessItem
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      armsBlock(squads)
      vehiclesBlock(squads)
    ]
  })
}

let freemiumBlockContent = {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        freemiumBlockHeader
        advantagesBlock
      ]
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      padding = fsh(2)
      children = [
        squadsBlock
        purchaseBlock
      ]
    }
  ]
}

let function freemiumInfoBlock(config) {
  let { backImage = null } = config
  return {
    size = flex()
    children = [
      mkImage(backImage, { keepAspect = KEEP_ASPECT_FILL })
      freemiumBlockContent
    ]
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        play = true, easing = OutCubic }
      { prop = AnimProp.translate, from = [0, -hdpx(250)], to = [0, 0],
        duration = 0.2, play = true, easing = OutQuad }
    ]
  }
}

let function open(campGroupId = null) {
  showCampaignGroup(campGroupId)
  showAnimation(true)
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_SOLID
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = bgColor
    stopMouse = true
    stopHover = true
    cursor = normal
    children = @() {
      size = flex()
      watch = [safeAreaBorders, campPresentation]
      maxHeight = fsh(100)
      flow = FLOW_HORIZONTAL
      padding = safeAreaBorders.value
      children = [
        {
          size = flex()
          children = {
            size = [flex(), ph(75)]
            maxWidth = hdpx(180)
            hplace = ALIGN_RIGHT
            children = mkImage("ui/gameImage/premium_decor_left.avif")
          }
        }
        {
          size = [WND_WIDTH, flex()]
          children = freemiumInfoBlock(campPresentation.value)
        }
        {
          size = flex()
          children = [
            {
              size = [flex(), ph(75)]
              maxWidth = hdpx(180)
              children = mkImage("ui/gameImage/premium_decor_right.avif")
            }
            closeBtnBase({
              padding = fsh(1)
              hplace = ALIGN_RIGHT
              onClick = close
            }).__update({ margin = fsh(1) })
          ]
        }
      ]
    }
    onClick = @() null
  })
}

console_register_command(@() open(), "ui.freemiumPromoWindow")

return open
