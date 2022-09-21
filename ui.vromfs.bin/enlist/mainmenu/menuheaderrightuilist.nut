from "%enlSqGlob/ui_library.nut" import *

let { horGap, emptyGap } = require("%enlist/components/commonComps.nut")
let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let premiumWidgetUi = require("%enlist/currency/premiumWidgetUi.nut")
let mainMenuBtn = require("%enlist/dropdownmenu/dropDownMenu.nut")
let profileWidget = require("%enlist/profile/profileWidget.nut")


let currenciesBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = currenciesWidgetUi
}

let premiumBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    premiumWidgetUi
    emptyGap
  ]
}

return [
  currenciesBlock,
  emptyGap,
  armyCurrencyUi,
  horGap,
  premiumBlock,
  profileWidget,
  mainMenuBtn
]
