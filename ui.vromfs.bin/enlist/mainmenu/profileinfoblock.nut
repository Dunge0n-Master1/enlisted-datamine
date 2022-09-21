from "%enlSqGlob/ui_library.nut" import *

let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let { columnGap, bigPadding } = require("%enlSqGlob/ui/designConst.nut")
let dropDownMenu =  require("%enlist/dropdownmenu/dropDownMenu.nut")
let profileButton = require("%enlist/profile/profileButton.nut")
let premiumWidgetUi = require("%enlist/premium/premiumButtonUi.nut")


let currencies = {
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = [
    currenciesWidgetUi
    armyCurrencyUi
  ]
}

let profileInfoBlock = {
  flow = FLOW_VERTICAL
  gap = columnGap
  hplace = ALIGN_RIGHT
  padding = [bigPadding, 0, 0, 0]
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = columnGap
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children =  [
        profileButton
        premiumWidgetUi
        dropDownMenu
      ]
    }
    currencies
  ]
}

return profileInfoBlock
