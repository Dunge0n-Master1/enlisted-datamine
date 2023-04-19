from "%enlSqGlob/ui_library.nut" import *

let { blurBgFillColor, commonBtnHeight, accentColor, squadElemsBgHoverColor,
  squadElemsBgColor, disabledTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { TextNormal, TextHover } = require("%ui/components/textButton.style.nut")

let { ControlBgOpaque } = require("%ui/style/colors.nut")

let styles = freeze({
  rowHeight = commonBtnHeight
  notFoundMsg = { color = TextNormal }.__update(body_txt)
  errorTxtStyle = { color = accentColor }.__update(body_txt)
  noteStyle = sub_txt
  panelScreenOffset = [hdpx(390), -hdpx(770)]

  textState = @(sf, isPrem) {
    color = sf & S_HOVER ? TextHover : isPrem ? disabledTxtColor : TextNormal
    padding = fsh(1)
  }.__update(body_txt)

  bgState = @(sf, isPrem) {
    fillColor = sf & S_HOVER ? squadElemsBgHoverColor
      : isPrem ? ControlBgOpaque : squadElemsBgColor
  }

  panelStyle = {
    panelBgColor = blurBgFillColor
    headerFillColor = blurBgFillColor
    headerTxtColor = TextNormal
  }

})

return styles
