from "%enlSqGlob/ui_library.nut" import *

let {addModalWindow, removeModalWindow} = require("%darg/components/modalWindows.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let {
  giant_txt, h0_txt, h1_txt, h2_txt, body_txt, tiny_txt
} = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { premiumProducts } = require("%enlist/shop/armyShopState.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { premiumActiveInfo, premiumImage } = require("premiumComp.nut")
let {
  bigPadding, smallPadding, accentTitleTxtColor, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { Purchase } = require("%ui/components/textButton.nut")
let { get_setting_by_blk_path } = require("settings")
let openUrl = require("%ui/components/openUrl.nut")
let { mkHeaderFlag, primeFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")

let linkToOpen = get_setting_by_blk_path("premiumUrl")

const WND_UID = "premiumWindow"
let WND_WIDTH = fsh(120)
let ANIM_DELAY = 0.1
let ANIM_TIME = 0.3
let BLINK_DELAY = 0.2
let BONUSES_TEXT_DELAY = 2.0

let premWndParams = {
  bgColor = Color(11, 11, 19)
  baseColor  = Color(112, 112, 112)
  activeColor  = Color(219, 219, 219)
  promoColor  = accentTitleTxtColor
}

let defaultPremiumDays = 30
let curSelectedDays = Watched(defaultPremiumDays)
let showAnimation = Watched(true)
let stateFlag = Watched(0)

let mkImage = @(path, customStyle = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(customStyle)

let close = @() removeModalWindow(WND_UID)

let premiumBlockHeader = mkHeaderFlag(
  {
    padding = [fsh(2), fsh(3)]
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(loc("premium/title"))
  }.__update(h1_txt),
  primeFlagStyle
)


let mkPremiumDescAnim = @(delay) !showAnimation.value ? {} : {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay + 0.05,
      play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = ANIM_TIME,
      delay, play = true, easing = OutQuad }
    { prop = AnimProp.translate, from = [0, -hdpx(150)], to = [0, 0],
      duration = ANIM_TIME, delay, play = true, easing = OutQuad, onFinish = @() showAnimation(false) }
  ]
}

let mkPremiumValAnim = @(delay, c1, c2) [
  { prop = AnimProp.color, from = c1, to = c2, duration = 0.75,
    play = true, delay }
  { prop = AnimProp.color, from = c2, to = c2, duration = 0.15,
    play = true, delay = delay + 0.7 }
  { prop = AnimProp.color, from = c2, to = c1, duration = 0.55,
    play = true, delay = delay + 0.8 }
  { prop = AnimProp.scale, from = [1,1], to = [1.1,1.1], duration = 0.25,
    play = true, delay }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1.1,1.1], duration = 0.35,
    play = true, delay = delay + 0.2 }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1,1], duration = 0.45,
    play = true, delay = delay + 0.5 }
]

let function premiumDesc(idx, unitVal, descText, unitDesc = null) {
  let { activeColor, promoColor} = premWndParams
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = fsh(2)
    children = [
      {
        flow = FLOW_HORIZONTAL
        children = [
          txt({
            text = unitVal
            color = promoColor
            transform = {}
            animations = mkPremiumValAnim(BLINK_DELAY * idx + BONUSES_TEXT_DELAY,
              promoColor, activeColor)
          }.__update(giant_txt))
          unitDesc == null ? null
            : txt({
                text = unitDesc
                color = activeColor
                padding = [0, bigPadding]
              }.__update(h2_txt))
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = [
          { size = [hdpx(40), 0]}
          noteTextArea(descText).__update({ color = activeColor }, body_txt)
        ]
      }
    ]
  }.__update(mkPremiumDescAnim(ANIM_DELAY * idx))
}

let function premiumDescBlock() {
  let { premiumBonuses = null } = gameProfile.value
  let {
    premiumExpMul = 1, maxSquadsInBattle = 0, soldiersReserve = 0
  } = premiumBonuses
  let expBonus = 100 * (premiumExpMul - 1)
  return @() {
    watch = gameProfile
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = {
      rendObj = ROBJ_SOLID
      size = [hdpx(1), flex()]
      color = premWndParams.baseColor
      margin = bigPadding
    }
    children = [
      premiumDesc(0, $"+{expBonus}%", loc("premiumDescExp"), loc("exp"))
      premiumDesc(2, $"+{maxSquadsInBattle}", loc("premiumDescSquadUnits"))
      premiumDesc(3, $"+{soldiersReserve}", loc("premiumDescReserve"))
      premiumDesc(4, "+2", loc("premiumDecalSlots"))
    ]
  }
}

let function onPurchase(shopItem, premItemView) {
  buyShopItem({
    shopItem
    productView = {
      flow = FLOW_VERTICAL
      margin = [0,0,fsh(3),0]
      halign = ALIGN_CENTER
      gap = hdpx(30)
      children = [
        premiumBlockHeader
        premItemView
      ]
    }
  })
  sendBigQueryUIEvent("action_buy_premium", "premium_promo")
}

let function mkDiscountLine(discountInPercent, override = {}) {
  return discountInPercent <= 0 ? null
  : {
    size = SIZE_TO_CONTENT
    hplace = ALIGN_RIGHT
    margin = [0, 0, smallPadding, 0]
    children = [
          mkImage("!ui/gameImage/discount_corner.svg")
          txt({
            text = $"-{discountInPercent}%"
            color  = Color(0,0,0)
            hplace = ALIGN_RIGHT
            vplace = ALIGN_CENTER
            margin = [0, smallPadding]
          }.__update(body_txt))
        ]
  }.__update(override)
}

let function mkPremItemView(sf, selected, size, premiumDays, saveVal) {
  let { baseColor, activeColor, promoColor } = premWndParams
  let daysColor = selected ? promoColor : baseColor
  return {
    rendObj = ROBJ_BOX
    size
    borderWidth = (sf & S_HOVER) || selected ? hdpx(1) : 0
    borderColor = promoColor
    children = [
      (sf & S_HOVER) || selected ? null
        : {
            size = flex()
            children = [
              {
                rendObj = ROBJ_BOX
                size = [pw(15), pw(15)]
                borderWidth = [hdpx(1),0,0,hdpx(1)]
                borderColor = baseColor
              }
              {
                rendObj = ROBJ_BOX
                size = [pw(15), pw(15)]
                hplace = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                borderWidth = [0,hdpx(1),hdpx(1),0]
                borderColor = baseColor
              }
            ]
          }
      {
        flow = FLOW_VERTICAL
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          saveVal <= 0 ? null
            : txt({
                text = loc("shop/youSave", { percents = saveVal })
              }).__update(tiny_txt)
          txt({
            text = premiumDays
            color = daysColor
          }.__update(h0_txt))
          txt({
            text = loc("premiumDays", { days = premiumDays })
            color = activeColor
          }.__update(h2_txt))
        ]
      }
    ]
  }
}

let purchaseButton = @(action, params = {}) Purchase(loc("btn/buy"), action, {
  margin = 0
  size = [flex(), commonBtnHeight]
  hotkeys = [ ["^J:Y", {description={ skip=true } sound="click"}] ]
}.__update(params))

let mkPremItem = kwarg(
  function(shopItem, idx, premSize, maxDayPrice, currencies, curSelectedDaysWatch) {
    let { activeColor, baseColor } = premWndParams
    let { premiumDays = 0, discountInPercent = 0, curShopItemPrice = {} } = shopItem
    local { currencyId = "", price = 0, fullPrice = 0 } = curShopItemPrice

    if (premiumDays == 0 || price == 0 || currencyId == "")
      return null

    let currency = currencies.findvalue(@(c) c.id == currencyId)
    if (currency == null)
      return null

    let isSelected = curSelectedDaysWatch.value == premiumDays
    fullPrice = discountInPercent == 0 ? price : fullPrice
    let saveVal = premiumDays <= 0 || maxDayPrice <= 0 ? 0
      : 100 - 100 * (fullPrice / premiumDays) / maxDayPrice
    let cellSize = [premSize, premSize]
    let sf = stateFlag.value

    return @(){
      watch = stateFlag
      behavior = Behaviors.Button
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      size = [premSize + hdpx(20), SIZE_TO_CONTENT]
      onClick = @() isSelected
        ? onPurchase(shopItem, mkPremItemView(sf, true, cellSize, premiumDays, saveVal))
        : curSelectedDaysWatch(premiumDays)
      children = [
        mkPremItemView(sf, isSelected, cellSize, premiumDays, saveVal)
          .__update(mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
        {
          size =[flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          children = [
            mkCurrency({
              currency
              price
              fullPrice
              txtStyle = { color = activeColor }.__update(body_txt)
              discountStyle = { color = activeColor }.__update(body_txt)
              dimStyle = { color = baseColor}.__update(body_txt)
              iconSize = hdpx(20)
            }).__update({
                size = [premSize, SIZE_TO_CONTENT]
                margin = [fsh(2), 0, fsh(1), 0]
              }),
            mkDiscountLine(discountInPercent, mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
          ]
        }
        !isSelected ? null :
          purchaseButton(@() onPurchase(shopItem,
            mkPremItemView(sf, true, cellSize,  premiumDays, saveVal)))
      ]
    }.__update(mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
  })

let function premiumBuyBlockUi() {
  let res = {
    watch = [premiumProducts, currenciesList, curSelectedDays]
  }
  let premiumShopItems = premiumProducts.value
  if (premiumShopItems.len() == 0)
    return res

  let maxDayPrice = premiumShopItems.reduce(function(maxPrice, val) {
    let days = val.premiumDays
    let price = days > 0 ? val.curShopItemPrice.price / days : 0
    return max(price, maxPrice)
  }, 0)
  let premSize = min((WND_WIDTH / premiumShopItems.len()) - hdpx(36), hdpx(220))
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = { size = flex() }
    children = premiumShopItems.map(@(shopItem, idx) mkPremItem({
      shopItem, idx, premSize, maxDayPrice,
      currencies = currenciesList.value,
      curSelectedDaysWatch = curSelectedDays
    }))
  })
}

let premiumBuyBlockBtn = {
  size = [pw(30), flex()]
  hplace = ALIGN_CENTER
  minWidth = SIZE_TO_CONTENT
  children = purchaseButton(@() openUrl(linkToOpen))
}

let premiumInfo = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  padding = fsh(2)
  children = [
    premiumImage(hdpx(80))
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = fsh(1)
      children = [
        noteTextArea(loc("premiumDescBase"))
          .__update({
            color = premWndParams.activeColor
          }, body_txt)
        {
          size = flex()
          halign = ALIGN_RIGHT
          children = premiumActiveInfo(h2_txt, premWndParams.promoColor)
        }
      ]
    }
  ]
}

let premiumBlockContent = @() {
  size = flex()
  flow = FLOW_VERTICAL
  gap = fsh(9)
  children = [
    premiumInfo
    { size = flex() }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(30)
      children = [
        premiumBlockHeader
        premiumDescBlock()
      ]
    }
    linkToOpen != null ? premiumBuyBlockBtn : premiumBuyBlockUi
  ]
}

let premiumInfoBlock = @() {
  size = flex()
  children = [
    mkImage("ui/gameImage/premium_bg.jpg", { keepAspect = true })
    premiumBlockContent()
  ]
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      play = true, easing = OutCubic }
    { prop = AnimProp.translate, from = [0, -hdpx(250)], to = [0, 0],
      duration = 0.2, play = true, easing = OutQuad }
  ]
}

let function open() {
  curSelectedDays(defaultPremiumDays)
  showAnimation(true)
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_SOLID
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = premWndParams.bgColor
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
          children = premiumInfoBlock()
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

return open
