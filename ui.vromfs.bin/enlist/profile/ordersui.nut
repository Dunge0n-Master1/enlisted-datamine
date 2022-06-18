from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { realCurrencies } = require("%enlist/shop/armyShopState.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  getCurrencyPresentation
} = require("%enlist/shop/currencyPresentation.nut")
let { mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let {
  activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")


let mkCurrency = @(currencyTpl) {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkCurrencyImage(getCurrencyPresentation(currencyTpl).icon,
      [hdpx(160), hdpx(160)])
    txt({
      text = 1
      color = activeTxtColor
    }).__update(body_txt)
  ]
}

let currenciesUi = @() {
  watch = realCurrencies
  children = wrap(realCurrencies.value.keys().map(mkCurrency),
    {
      width = sh(100)
      hGap = sh(1)
      vGap = sh(1)
      halign = ALIGN_CENTER
    })
}

return {
  size = [SIZE_TO_CONTENT, flex()]
  margin = [sh(2), 0]
  children = currenciesUi
}
