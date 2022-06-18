from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let colorize = require("%ui/components/colorize.nut")
let { MsgMarkedText } = require("%ui/style/colors.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")

let defGap = fsh(3)

let function show(
  purchase, priceView, title = "", productView = null, additionalButtons = [],
  description = null, currenciesAmount = null
) {
  let params = {
    topPanel = currenciesAmount
    text = colorize(MsgMarkedText, title)
    fontStyle = body_txt
    children = {
      size = [fsh(80), SIZE_TO_CONTENT]
      margin = defGap
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = defGap
      children = [
        productView
        description
        {
          flow = FLOW_HORIZONTAL
          children = [
            {
              rendObj = ROBJ_TEXT
              text = "{0} ".subst(loc("shop/willCostYou"))
            }.__update(sub_txt)
            priceView
          ]
        }
      ]
    }
    buttons = [{
      text = loc("btn/buy")
      action = purchase
      customStyle = {
        hotkeys = [[ "^J:Y | Enter | Space", { description = {skip = true}} ]]
      }.__merge(primaryFlatButtonStyle)
    }]
    .append({ text = loc("Cancel") })
    .extend(additionalButtons)
  }
  msgbox.showWithCloseButton(params)
}

return kwarg(show)
