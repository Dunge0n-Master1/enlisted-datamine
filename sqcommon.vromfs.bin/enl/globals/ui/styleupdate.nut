from "%enlSqGlob/ui_library.nut" import *

let { blurBgColor, blurBgFillColor, accentColor } = require("%enlSqGlob/ui/viewConst.nut")
let textButton = require("%ui/components/textButton.nut")
let {
  primaryFlatButtonStyle, purchaseButtonStyle
} = require("%enlSqGlob/ui/buttonsStyle.nut")
textButton.override.__update({ borderRadius = 0 })

textButton.primaryButtonStyle.__update({borderRadius = 0}, primaryFlatButtonStyle)

textButton.loginBtnStyle.__update({
  borderRadius = 0,
  borderWidth = 0,
  style = {
    BgNormal = accentColor
  }
})

textButton.onlinePurchaseStyle.__update({
  borderRadius = 0,
  borderWidth = 0
}, purchaseButtonStyle)

textButton.setDefaultButton(@(text, handler, params = {}) textButton.Bordered(text, handler, {borderWidth = 1, borderColor=Color(40,40,40,2)}.__merge(params)))

require("%ui/components/modalPopupWnd.nut").POPUP_PARAMS.__update({
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  borderRadius = 0
})