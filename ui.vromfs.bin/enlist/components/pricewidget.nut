from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { currenciesById } = require("%enlist/currency/currencies.nut")

let priceWidget = function(price, currencyId) {
  let currency = currenciesById.value?[currencyId]
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      currency == null ? null : {
        size = [hdpx(30), hdpx(30)]
        rendObj = ROBJ_IMAGE
        image = Picture(currency.image(hdpx(30)))
      }
      {
        rendObj = ROBJ_TEXT
        text = currency
          ? price
          : loc($"priceText/{currencyId}", { price }, $"{price}{currencyId}")
      }.__update(body_txt)
    ]
  }
}

return {
  priceWidget
}