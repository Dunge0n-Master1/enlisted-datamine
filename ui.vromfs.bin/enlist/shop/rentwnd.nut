from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { Bordered, Purchase } = require("%ui/components/textButton.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { btnSizeBig } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let {
  addModalWindow, removeModalWindow
} = require("%ui/components/modalWindows.nut")
let {
  bigPadding, bigOffset, rowBg, activeTxtColor, blurBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { rentSquad } = require("%enlist/shop/rentState.nut")


const WND_UID = "rentWindow"

let priceWidth = hdpx(120)
let priceTxtStyle = { color = activeTxtColor }.__update(body_txt)

let function mkRentOption(opt, idx, armyId, squadId, currency) {
  let { rentTime, price } = opt
  let rentTimeTxt = loc("btn/rentFor", {
    timeText = secondsToHoursLoc(rentTime)
  })
  return {
    flow = FLOW_HORIZONTAL
    padding = [bigPadding, bigOffset]
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = rowBg(0, idx)
    children = [
      Purchase(rentTimeTxt,
        function() {
          rentSquad(armyId, squadId, rentTime, price)
          removeModalWindow(WND_UID)
        },
        {
          size = btnSizeBig
          margin = 0
        })
      {
        size = [priceWidth, SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        children = mkCurrency({ currency, price, txtStyle = priceTxtStyle})
      }
    ]
  }
}

let function mkRentWindow(rentOptions, armyId, squadId) {
  return {
    key = WND_UID
    size = flex()
    flow = FLOW_VERTICAL
    gap = hdpx(40)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    onClick = @() null
    children = [
      function() {
        let currency = currenciesList.value.findvalue(@(c) c.id == "EnlistedGold")
        return {
          watch = currenciesList
          flow = FLOW_VERTICAL
          children = rentOptions.map(@(opt, idx)
            mkRentOption(opt, idx, armyId, squadId, currency))
        }
      }
      Bordered(loc("Cancel"), @() removeModalWindow(WND_UID), { margin = 0 })
    ]
  }
}

let function open(rentOptions, armyId, squadId) {
  addModalWindow(mkRentWindow(rentOptions, armyId, squadId))
}

return open