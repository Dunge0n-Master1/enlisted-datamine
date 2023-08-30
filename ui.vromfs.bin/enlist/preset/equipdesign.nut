from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, titleTxtColor, disabledTxtColor, darkPanelBgColor, panelBgColor,
  hoverPanelBgColor, defSlotBgColor, fullTransparentBgColor, commonBtnHeight, midPadding,
  attentionTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")

let defTxtStyle = { color = defTxtColor }.__update(fontBody)
let hoverTxtStyle = { color = titleTxtColor }.__update(fontBody)
let disabledTxtStyle = { color = disabledTxtColor }.__update(fontBody)
let notFoundHeader = { color = attentionTxtColor }.__update(fontBody)
let noteStyle = { color = titleTxtColor }.__update(fontSub)

let styles = freeze({
  notFoundMsg = defTxtStyle
  notFoundHeader
  noteStyle
  rowHeight = commonBtnHeight

  closeBtnStyle = {
    padding = midPadding
    fontSize = fontBody.fontSize
    color = defTxtColor
  }

  textState = @(sf, isPrem) {
    padding = midPadding
  }.__update(sf & S_HOVER ? hoverTxtStyle
    : isPrem ? disabledTxtStyle
    : defTxtStyle)

  bgState = @(sf, isPrem) {
    fillColor = sf & S_HOVER ? hoverPanelBgColor
      : isPrem ? darkPanelBgColor
      : panelBgColor
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
  }.__update(fontBody)

  hoverInputStyle = {
    padding = [0, 0, 0, midPadding]
    colors = {
      textColor = titleTxtColor,
      backGroundColor = hoverPanelBgColor
    }
  }.__update(fontBody)

})

return styles
