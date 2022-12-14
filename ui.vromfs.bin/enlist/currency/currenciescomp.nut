from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { TextHover, TextNormal } = require("%ui/components/textButton.style.nut")
let { Purchase } = require("%ui/components/textButton.nut")
let {
  gap, bonusColor, defTxtColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { currenciesExpiring, currenciesById } = require("%enlist/currency/currencies.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let {
  mkCurrencyTooltipContainer, mkDefaultTooltipText
} = require("%enlist/shop/currencyComp.nut")


let curencyById = @(currencyId) currenciesById.value?[currencyId]

let oldPriceLine = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
  commands = [[ VECTOR_LINE, -5, 50, 105, 50 ]]
}

let mkCurrencyImg = @(currency, iconSize) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture(currency.image(iconSize))
}

let mkCurrencyCount = @(count, txtStyle = { color = activeTxtColor }) {
  rendObj = ROBJ_TEXT
  text = count
}.__update(body_txt, txtStyle)

let mkCurrencyStroke = @(count, txtStyle = { color = activeTxtColor }) {
  children = [
    mkCurrencyCount(count, txtStyle)
    oldPriceLine.__merge(txtStyle)
  ]
}

let mkCurrency = kwarg(
  function(currency, price, fullPrice = null, iconSize = hdpx(16),
    txtStyle = { color = activeTxtColor },
    discountStyle = { color = bonusColor },
    dimStyle = { color = defTxtColor }
  ) {
    let hasPrice = price != null
    let hasDiscount = (fullPrice ?? 0) > price && (price ?? 0) >= 0
    return {
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        hasPrice && hasDiscount
          ? {
              flow = FLOW_HORIZONTAL
              valign = ALIGN_CENTER
              gap = gap
              children = [
                mkCurrencyImg(currency, hdpx(10))
                mkCurrencyStroke(fullPrice, dimStyle.__update(tiny_txt))
              ]
            }
          : null
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = gap
          children = [
            mkCurrencyImg(currency, iconSize)
            hasPrice
              ? mkCurrencyCount(price, hasDiscount ? discountStyle : txtStyle)
              : mkDefaultTooltipText(loc("currency/notAvailable"))
          ]
        }
      ]
    }

  })

let function currencyBtn(
  btnText, currencyId, price = null, priceFull = null, cb = @() null,
  style = {}, txtColor = TextNormal, txtHoverColor = TextHover,
  discountStyle = { color = bonusColor }
) {
  let hasPrice = !("" == (price ?? ""))
  let hasPriceFull = !("" == (priceFull ?? ""))
  return Purchase(btnText, cb, style.__merge({
    textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = textField?.margin
      gap = gap
      children = [
        textField.__merge({
          margin = [0, hdpx(10), 0, 0]
          color = sf & S_HOVER ? txtHoverColor : txtColor
        })
        mkCurrencyImg(curencyById(currencyId), hdpx(30))
        hasPrice
          ? mkCurrencyCount(price, hasPriceFull
              ? discountStyle
              : { color = sf & S_HOVER ? txtHoverColor : txtColor })
          : null
        hasPrice && hasPriceFull
          ? mkCurrencyStroke(priceFull, { color = sf & S_HOVER ? txtHoverColor : txtColor })
          : null
      ]
    }, params, handler, group, sf)
  }))
}

let function mkExpireRow(expData, currency) {
  let { expireAt, amount } = expData
  let timeText = Computed(function() {
    let timeLeft = expireAt - serverTime.value
    return timeLeft > 0 ? secondsToHoursLoc(timeLeft) : loc("expired")
  })

  let replaceList = {
    ["{amount}"] = [ //warning disable: -forgot-subst
      mkCurrencyImg(currency, hdpx(20))
      mkDefaultTooltipText(amount)
    ],
    ["{time}"] = @() mkDefaultTooltipText(timeText.value).__update({watch = timeText}) //warning disable: -forgot-subst
  }
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = mkTextRow(loc("currency/expireAt"), mkDefaultTooltipText, replaceList)
  }
}

let mkCurrencyTooltip = @(currency) function() {
  let exp = currenciesExpiring.value?[currency.id]
  if (exp == null)
    return mkCurrencyTooltipContainer(
      loc(currency?.locId),
      loc(currency?.descLocId)
    )

  let res = { watch = currenciesExpiring }
  return res.__update(tooltipBox({
    flow = FLOW_VERTICAL
    children = exp.sort(@(a, b) a.expireAt <=> b.expireAt)
      .map(@(e) mkExpireRow(e, currency))
  }))
}

return {
  mkCurrency
  currencyBtn = kwarg(currencyBtn)
  mkCurrencyImg
  mkCurrencyCount
  mkCurrencyTooltip
  oldPriceLine
}
