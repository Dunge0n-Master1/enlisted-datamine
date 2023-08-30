from "%enlSqGlob/ui_library.nut" import *

let armyCurrencyUi = require("%enlist/shop/armyCurrencyUi.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let { largePadding } = require("%enlSqGlob/ui/designConst.nut")
let dropDownMainMenu =  require("%enlist/dropdownmenu/dropDownMainMenu.nut")
let profileButton = require("%enlist/profile/profileButton.nut")
let premiumWidgetUi = require("%enlist/premium/premiumButtonUi.nut")


let currencies = {
  flow = FLOW_HORIZONTAL
  gap = largePadding
  children = [
    currenciesWidgetUi
    armyCurrencyUi
  ]
}

let profileInfoBlock = {
  flow = FLOW_VERTICAL
  gap = largePadding
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = largePadding
      valign = ALIGN_BOTTOM
      children =  [
        profileButton
        premiumWidgetUi
        dropDownMainMenu
      ]
    }
    currencies
  ]
}

return profileInfoBlock
