from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, titleTxtColor, disabledTxtColor, darkPanelBgColor, panelBgColor,
  hoverPanelBgColor, defSlotBgColor, fullTransparentBgColor, commonBtnHeight, midPadding,
  attentionTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { fontLarge, fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontLarge)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let disabledTxtStyle = { color = disabledTxtColor }.__update(fontLarge)
let notFoundHeader = { color = attentionTxtColor }.__update(fontLarge)
let noteStyle = { color = titleTxtColor }.__update(fontSmall)

let styles = freeze({
  notFoundMsg = defTxtStyle
  notFoundHeader
  noteStyle
  rowHeight = commonBtnHeight

  closeBtnStyle = {
    padding = midPadding
    fontSize = fontMedium.fontSize
    color = defTxtColor
  }

  textState = @(sf, isPrem) {
    padding = midPadding
  }.__update(sf & S_HOVER ? hoverTxtStyle
    : isPrem ? disabledTxtStyle : defTxtStyle)

  bgState = @(sf, isPrem) {
    fillColor = sf & S_HOVER ? hoverPanelBgColor
      : isPrem ? darkPanelBgColor : panelBgColor
  }

  innerBtnStyle = {
    style = {
      hoverPanelBgColor = fullTransparentBgColor
      defBgColor = fullTransparentBgColor
      defBdColor = fullTransparentBgColor
    }
  }

  defInputStyle = {
    padding = [0, 0, 0, midPadding]
    colors = {
      textColor = defTxtColor
      backGroundColor = defSlotBgColor
    }
  }.__update(fontLarge)

  hoverInputStyle = {
    padding = [0, 0, 0, midPadding]
    colors = {
      textColor = titleTxtColor,
      backGroundColor = hoverPanelBgColor
    }
  }.__update(fontLarge)

})

return styles
