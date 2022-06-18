from "%enlSqGlob/ui_library.nut" import *

let {addModalWindow, removeModalWindow} = require("%darg/components/modalWindows.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let {
  h1_txt, h2_txt, body_txt, h1_bold_txt, fontawesome, sub_txt, h2_bold_txt
} = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  bigPadding, commonBtnHeight, freemiumColor, soldierLockedLvlColor, activeTxtColor,
  blurBgFillColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { curFreemiumShopItem, freemiumExpBoost
} = require("%enlist/campaigns/freemiumState.nut")
let fa = require("%darg/components/fontawesome.map.nut")
let {
  mkHeaderFlag, freemiumFlagStyle
}= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { iconByGameTemplate } = require("%enlSqGlob/ui/itemsInfo.nut")
let { weapInfoBtn } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let { openUnlockSquadScene } = require("%enlist/soldiers/unlockSquadScene.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")


const WND_UID = "freemiumWindow"
local WND_WIDTH = fsh(120)
local ANIM_DELAY = 0.1
local ANIM_TIME = 0.3
local BLINK_DELAY = 0.2
local BONUSES_TEXT_DELAY = 2.0

const bgColor = 0xFF0B0B13
const baseColor = 0xFF707070
const activeColor = 0xFFDBDBDB

local showAnimation = Watched(true)

local mkImage = @(path, customStyle = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(customStyle)

local close = @() removeModalWindow(WND_UID)

local mkValAnimColor = @(delay, c1, c2) !showAnimation.value ? [] : [
  { prop = AnimProp.color, from = c1, to = c2, duration = 0.75,
    play = true, delay }
  { prop = AnimProp.color, from = c2, to = c2, duration = 0.15,
    play = true, delay = delay + 0.7 }
  { prop = AnimProp.color, from = c2, to = c1, duration = 0.55,
    play = true, delay = delay + 0.8 }
]

local mkValAnimScale = @(delay) !showAnimation.value ? [] : [
  { prop = AnimProp.scale, from = [1,1], to = [1.1,1.1], duration = 0.25,
    play = true, delay }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1.1,1.1], duration = 0.35,
    play = true, delay = delay + 0.2 }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1,1], duration = 0.45,
    play = true, delay = delay + 0.5 }
]

let mkIconBar = @(count, color, fName) {
  rendObj = ROBJ_INSCRIPTION
  animations = mkValAnimColor(BLINK_DELAY * 2 + BONUSES_TEXT_DELAY,
    freemiumColor, activeColor )
  validateStaticText = false
  text = "".join(array(count, fa[fName]))
  font = fontawesome.font
  fontSize = hdpx(30)
  color
}

local freemiumBlockHeader = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(330)
  children = [
    {
      flow = FLOW_VERTICAL
      children = [
        mkHeaderFlag({
            rendObj = ROBJ_TEXT
            text = loc("freemium/title")
            padding = [fsh(2), fsh(3)]
          }.__update(h1_txt),
          freemiumFlagStyle)
        txt({
          text = loc("freemium/bothSide")
          padding = [hdpx(15), hdpx(30)]
          color = activeTxtColor
        }.__update(h2_txt))
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      children = {
        text = loc("freemium/desc")
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(420)
      }
    }
  ]
}

local mkDescAnim = @(delay) !showAnimation.value ? {} : {
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

local freemiumDesc = @(idx, unitVal, descText, unitDesc = null) {
  size = flex()
  flow = FLOW_VERTICAL
  padding = fsh(2)
  children = [
    {
      flow = FLOW_HORIZONTAL
      children = [
        txt({
          text = unitVal
          color = freemiumColor
          transform = {}
          animations = [].extend(
            mkValAnimColor(BLINK_DELAY * idx + BONUSES_TEXT_DELAY, freemiumColor, activeColor),
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
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(350)
      size = [flex(), SIZE_TO_CONTENT]
      margin = [hdpx(20), 0]
      text = descText
      color = activeColor
    }.__update(sub_txt)
  ]
}.__update(mkDescAnim(ANIM_DELAY * idx))


local freemiumDescBlock = @() {
  watch = freemiumExpBoost
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = {
    rendObj = ROBJ_SOLID
    size = [hdpx(1), flex()]
    color = baseColor
    margin = bigPadding
  }
  children = [
    freemiumDesc(0,
      $"x{freemiumExpBoost.value}",
      loc("freemium/discountDesc"),
      loc("freemium/expBonusDesc"))
    {
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      padding = fsh(2)
      children = [
        {
          flow = FLOW_HORIZONTAL
          animations = mkValAnimScale(BLINK_DELAY * 2 + BONUSES_TEXT_DELAY)
          transform = {}
          children = [
            mkIconBar(4, freemiumColor, "star"),
            mkIconBar(1, soldierLockedLvlColor, "star-o")
          ]
        },
        {
          text = loc("freemium/levelSquads")
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          maxWidth = hdpx(350)
          size = [flex(), SIZE_TO_CONTENT]
          margin = [hdpx(20), 0]
          color = activeColor
        }.__update(sub_txt)
      ]
    }.__update(mkDescAnim(ANIM_DELAY * 2))
    freemiumDesc(2, loc("freemium/anyTimeBuy"), loc("freemium/anyTimeBuyDesc"))
    freemiumDesc(3, loc("freemium/new"), loc("freemium/newDesc"))
  ]
}

local function onPurchase(shopItem) {
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
  local res = { watch = curFreemiumShopItem }
  if (curFreemiumShopItem.value == null)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    children = Flat(loc("freemium/getPack"), @() onPurchase(curFreemiumShopItem.value), {
      size = [SIZE_TO_CONTENT, commonBtnHeight]
      hplace = ALIGN_RIGHT
      margin = 0
      hotkeys = [ ["^J:Y", {description={ skip=true } sound="click"}] ]
      style = {
        BgNormal = freemiumColor
        TextNormal = 0xFFFFFFFF
      }
    })
  })
}

local function tankIcon(squad) {
  let squadCfg = squadsCfgById.value?[squad.armyId][squad.id]
  if (squadCfg == null)
    return null

  let tankTemplate = squadCfg.startVehicle
  let unlockInfo = {
    isNextToBuyExp = true
  }
  let squadData = squadCfg.__merge({
    armyId = squad.armyId, squadCfg, unlockInfo
  })
  return watchElemState(@(sf){
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_SOLID
        color = blurBgFillColor
        margin = [hdpx(40), 0, hdpx(10), 0]
        behavior = Behaviors.Button
        onClick = function() {
          openUnlockSquadScene(squadData, KWARG_NON_STRICT)
          close()
        }
        children = [
          iconByGameTemplate(tankTemplate, {
            width = hdpx(200)
            height = hdpx(90)
          })
          weapInfoBtn(sf)
        ]
      }
      txt(loc($"items/{tankTemplate}")).__update(body_txt)
    ]
  })
}

let tanksBlock = @() {
  watch = curFreemiumShopItem
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = txt({
    text = "+"
    fontSize = fsh(8)
    margin = [0, hdpx(15)]
    color = freemiumColor
  })
  children = curFreemiumShopItem.value?.squads.map(tankIcon)
}

local freemiumBlockContent = @() {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        freemiumBlockHeader
        freemiumDescBlock
      ]
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      padding = [hdpx(40), 0, hdpx(40), hdpx(50)]
      children = [
        tanksBlock
        {
          text = loc("freemium/giftTank")
          color = freemiumColor
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          maxWidth = hdpx(340)
        }.__update(h2_bold_txt)
        purchaseButton
      ]
    }
  ]
}

local freemiumInfoBlock = @() {
  size = flex()
  children = [
    mkImage("ui/gameImage/freemium_bg.png", { keepAspect = true })
    freemiumBlockContent()
  ]
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      play = true, easing = OutCubic }
    { prop = AnimProp.translate, from = [0, -hdpx(250)], to = [0, 0],
      duration = 0.2, play = true, easing = OutQuad }
  ]
}

local function open() {
  showAnimation(true)
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_SOLID
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = bgColor
    children = @() {
      size = flex()
      maxHeight = fsh(100)
      flow = FLOW_HORIZONTAL
      watch = safeAreaBorders
      padding = safeAreaBorders.value
      children = [
        {
          size = flex()
          children = {
            size = [flex(), ph(75)]
            maxWidth = hdpx(180)
            hplace = ALIGN_RIGHT
            children = mkImage("ui/gameImage/premium_decor_left.jpg")
          }
        }
        {
          size = [WND_WIDTH, flex()]
          children = freemiumInfoBlock()
        }
        {
          size = flex()
          children = [
            {
              size = [flex(), ph(75)]
              maxWidth = hdpx(180)
              children = mkImage("ui/gameImage/premium_decor_right.jpg")
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
