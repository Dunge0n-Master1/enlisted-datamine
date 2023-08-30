from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let colorize = require("%ui/components/colorize.nut")
let { MsgMarkedText } = require("%ui/style/colors.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")
let JB = require("%ui/control/gui_buttons.nut")

let defGap = fsh(3)

let function show(
  purchase, priceView, title = "", productView = null, additionalButtons = [],
  description = null, currenciesAmount = null
) {
  let params = {
    topPanel = currenciesAmount
    text = colorize(MsgMarkedText, title)
    fontStyle = fontBody
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
            }.__update(fontSub)
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
    .append({ text = loc("Cancel"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } })
    .extend(additionalButtons)
  }
  msgbox.showWithCloseButton(params)
}

return kwarg(show)
