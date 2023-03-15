from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  bigGap, smallPadding, defTxtColor, activeTxtColor, isWide, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { getCurrencyPresentation, ticketGroups } = require("currencyPresentation.nut")
let { Purchase } = require("%ui/components/textButton.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let cursors = require("%ui/style/cursors.nut")
let colorize = require("%ui/components/colorize.nut")

let mkDefaultTooltipText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = activeTxtColor
}.__update(sub_txt)

let mkCurrencyTooltipContainer = @(name, desc = null) tooltipBox({
  flow = FLOW_VERTICAL
  gap = bigGap
  children = [
    mkDefaultTooltipText(name),
    (desc == null || desc == "") ? null : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [fsh(30), SIZE_TO_CONTENT]
      text = desc
      color = defTxtColor
    }.__update(sub_txt)
  ]
})

let mkCurrencyTooltip = @(currencyTpl) mkCurrencyTooltipContainer(
  loc($"items/{currencyTpl}"),
  loc($"items/{currencyTpl}/desc", "")
)

let function mkCurrencyImage(icon, sizeArr = [hdpx(30), hdpx(30)]) {
  let svgSize = [sizeArr[0].tointeger(), sizeArr[1].tointeger()]
  return{
    rendObj = ROBJ_IMAGE
    size = sizeArr
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{icon}:{svgSize[0]}:{svgSize[1]}:K")
    fallbackImage = Picture($"!ui/uiskin/currency/weapon_order.svg:{svgSize[0]}:{svgSize[1]}:K")
  }
}


let iconTextRow = @(icon, text, sizeArr = [hdpx(10), hdpx(10)], textStyle = {}){
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkCurrencyImage(icon, sizeArr)
    {
      padding = [0, hdpx(3)]
      rendObj = ROBJ_TEXT
      text
    }.__update(sub_txt, textStyle)
  ]
}

let function cardsInRow(cards){
  return {
    gap = hdpx(20)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children =
      cards.map(@(value)
        iconTextRow(value.icon, value.amount, [hdpx(20),hdpx(25)]))
  }
}

let function mkCurrencyCardsTooltip(cardType, cards = [], expandOrders = false) {
  let descText = loc(ticketGroups[cardType].desc) ?? ""
  return tooltipBox({
    flow = FLOW_VERTICAL
    gap = bigGap
    children = [
      {
        rendObj = ROBJ_TEXT
        minWidth = hdpx(300)
        text = loc(ticketGroups[cardType].name)
        color = activeTxtColor
      }
      expandOrders ? null : cardsInRow(cards)
      descText == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        text = descText
        color = defTxtColor
      }.__update(sub_txt)
    ]
  })
}

let mkCurrencyInShop = @(cards){
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = SIZE_TO_CONTENT
  text = "|".join(cards.map(@(value)
    colorize(value.color, value.amount)))
}.__update(body_txt)

let mkCurrencyCommon = @(sf, summ){
  rendObj = ROBJ_TEXT
  color = sf & S_HOVER ? activeTxtColor : defTxtColor
  text = summ
}.__update(body_txt)

let function mkCurrencyOverall(cardType, cardsTable = {}, onClick = null,
                                  keySuffix = "", isShop = false) {

  let stateFlag = Watched(0)
  local currencySumm = 0
  let trigger = $"blink_{cardsTable}"
  let sortedCards = cardsTable
    .map(@(amount, key) getCurrencyPresentation(key).__merge({ amount }))
    .values()
    .sort(@(a, b) a.order <=> b.order)
  currencySumm = sortedCards.reduce(@(sum, value) sum + value.amount, 0)
  let expandOrders = isWide && isShop && (ticketGroups[cardType]?.expandedInShop ?? false)
  if (sortedCards.len() == 0)
    return null

  return @(){
    size = [SIZE_TO_CONTENT, flex()]
    watch = stateFlag
    onElemState = @(sf) stateFlag(sf)
    minHeight = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    margin = [0,0,0,hdpx(10)]
    onHover = @(on) cursors.setTooltip(on
      ? mkCurrencyCardsTooltip(cardType, sortedCards, expandOrders)
      : null)
    key = $"currency_{cardsTable}{keySuffix}"
    behavior = Behaviors.Button
    skipDirPadNav = true
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1,1], to = [1.3,1.3], duration = 0.2 }
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1.3,1.3], to = [1.3,1.3], duration = 1.2, delay = 0.2 }
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1.3,1.3], to = [1,1], duration = 0.2, delay = 1.4 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = 0, to = 30, duration = 0.25, delay = 0.4 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = 30, to = -30, duration = 0.45, delay = 0.6 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = -30, to = 0, duration = 0.25, delay = 1 }
    ]
    onClick = onClick
    children = [
      mkCurrencyImage(ticketGroups[cardType].icon, [hdpx(45), hdpx(30)])
      expandOrders
        ? mkCurrencyInShop(sortedCards)
        : mkCurrencyCommon(stateFlag.value, currencySumm)
    ]
  }
}

let function mkItemCurrency(currencyTpl, count, keySuffix = "", textStyle = {}) {
  let currentCurrency = getCurrencyPresentation(currencyTpl)
  return {
    key = $"currency_{currencyTpl}{keySuffix}"
    size = [SIZE_TO_CONTENT, flex()]
    minHeight = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = iconTextRow(currentCurrency?.icon, count, [hdpx(25),hdpx(25)], textStyle)
  }
}

let mkCurrencyButton = @(text, currency, count = null, cb = null, style = {})
  Purchase(text, cb, style.__merge({
    textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = textField?.margin
      children = [
        textField.__merge({ margin = [0, hdpx(10), 0, 0] })
        mkCurrencyImage(currency)
        "" ==  (count ?? "") ? null : {
          rendObj = ROBJ_TEXT
          color = defTxtColor
          text = count
        }.__update(body_txt)
      ]
    }, params, handler, group, sf)
  }))

let mkLogisticsPromoMsgbox = @(currencies, buttons = []) msgbox.showMessageWithContent({
  uid = "logistics_promo"
  content = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = fsh(3)
    children = [
      txt(loc("menu/enlistedShop")).__update({
        color = activeTxtColor
      }, h2_txt)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        color = defTxtColor
        text = loc("menu/enlistedShopDesc")
      }
      {
        flow = FLOW_VERTICAL
        gap = bigGap
        children = currencies.map(@(currencyTpl) {
          gap = bigGap
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          children = [
            mkCurrencyImage(getCurrencyPresentation(currencyTpl).icon, [hdpx(70), hdpx(70)])
            {
              size = [hdpx(300), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = smallPadding
              children = [
                txt(loc($"items/{currencyTpl}")).__update({
                  color = activeTxtColor
                }, sub_txt)
                {
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  size = [flex(), SIZE_TO_CONTENT]
                  text = loc($"items/{currencyTpl}/desc", "")
                  color = defTxtColor
                }.__update(sub_txt)
              ]
            }
          ]
        })
      }
    ]
  }
  buttons
})

let function mkDiscountWidget(discountInPercent, override = {}) {
  if (discountInPercent <= 0)
    return null

  let { size = [hdpx(68), hdpx(34)] } = override

  return {
    size
    hplace = ALIGN_RIGHT
    children = [
      {
        rendObj = ROBJ_IMAGE
        size
        imageValign = ALIGN_TOP
        image = Picture($"!ui/gameImage/discount_corner.svg:{size[0].tointeger()}:{size[1].tointeger()}:K")
        color = accentTitleTxtColor
      }
      txt({
        text = $"-{discountInPercent}%"
        color  = Color(0,0,0)
        vplace = ALIGN_CENTER
        margin = [0, 0, 0, smallPadding]
      }.__update(override?.textStyle ?? body_txt))
    ]
  }.__update(override)
}

return {
  mkCurrencyOverall
  mkCurrencyTooltip
  mkCurrencyTooltipContainer
  mkDefaultTooltipText
  mkCurrencyImage
  mkCurrencyButton = kwarg(mkCurrencyButton)
  mkItemCurrency = kwarg(mkItemCurrency)
  mkLogisticsPromoMsgbox
  mkDiscountWidget
}
