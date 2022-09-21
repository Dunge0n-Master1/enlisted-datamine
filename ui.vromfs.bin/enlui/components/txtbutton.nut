from "%enlSqGlob/ui_library.nut" import *

let { fontLarge, fontFontawesome, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let {
  disabledTxtColor, defTxtColor, hoverTxtColor, titleTxtColor, panelBgColor,
  disabledBgColor, hoverBgColor, commonBtnHeight, smallBtnHeight, defBdColor,
  activeBdColor, hoverBdColor, activeBgColor, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")
let fa = require("%ui/components/fontawesome.map.nut")

let defTxtStyle = {
  defTxtColor
  hoverTxtColor
  activeTxtColor = titleTxtColor
  disabledTxtColor
}

let function textColor(sf, style = {}, isEnabled = true) {
  let txtColor = defTxtStyle.__merge(style)
  if (!isEnabled) return txtColor.disabledTxtColor
  if (sf & S_ACTIVE)    return txtColor.activeTxtColor
  if (sf & S_HOVER)     return txtColor.hoverTxtColor
  if (sf & S_KB_FOCUS)  return txtColor.hoverTxtColor
  return txtColor.defTxtColor
}

let defBorderStyle = {
  defBdColor
  hoverBdColor
  activeBdColor
}

let function borderColor(sf, style = {}) {
  let bdColor = defBorderStyle.__merge(style)
  if (sf & S_ACTIVE)    return bdColor.activeBdColor
  if (sf & S_HOVER)     return bdColor.hoverBdColor
  if (sf & S_KB_FOCUS)  return bdColor.hoverBdColor
  return bdColor.defBdColor
}

let defBgStyle = {
  defBgColor = panelBgColor
  hoverBgColor
  activeBgColor
  disabledBgColor
}

let function fillColor(sf, style = {}, isEnabled = true) {
  let bgColor = defBgStyle.__merge(style)
  if (!isEnabled)       return bgColor.disabledBgColor
  if (sf & S_ACTIVE)    return bgColor.activeBgColor
  if (sf & S_HOVER)     return bgColor.hoverBgColor
  if (sf & S_KB_FOCUS)  return bgColor.hoverBgColor
  return bgColor.defBgColor
}

let defTextCtor = @(text, _params, _handler, _group, _sf) text
let textButton = @(fill_color, border_width) function(text, handler, params={}) {
  let group = ElemGroup()
  let { stateFlags = Watched(0) } = params
  let function builder(sf) {
    let {
      txtFont = fontLarge, isEnabled = true, style = {}, bgChild = null, fgChild = null,
      btnHeight = commonBtnHeight, btnWidth = null
    } = params
    let sound = isEnabled ? params?.style.sound ?? params?.sound : null
    let minWidth = btnWidth ?? SIZE_TO_CONTENT
    return {
      watch = stateFlags
      rendObj = ROBJ_BOX
      fillColor = fill_color(sf, style, isEnabled)
      borderWidth = isEnabled ? border_width : 0
      borderRadius = commonBorderRadius
      borderColor = borderColor(sf, style)
      size = [btnWidth ?? SIZE_TO_CONTENT, btnHeight]
      key = handler
      group
      minWidth
      onElemState = @(v) stateFlags(v)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      clipChildren = true
      behavior = Behaviors.Button
      onDetach = @() stateFlags(0)
      onClick = isEnabled ? handler : null
      sound = {
        click  = "ui/enlist/button_click"
        hover  = "ui/enlist/button_highlight"
        active = "ui/enlist/button_action"
      }

      children = [
        bgChild
        defTextCtor({
          rendObj = ROBJ_TEXT
          text = (type(text)=="function") ? text() : text
          color = textColor(sf, style, isEnabled)
          maxWidth = pw(100)
          ellipsis = false
          margin = [fsh(1), fsh(3)]
          group
          behavior = [Behaviors.Marquee]
          delay = 0.5
          scrollOnHover = true
          speed = [hdpx(100),hdpx(700)]
        }.__update(txtFont), params, handler, group, sf,)
        fgChild
      ]
    }.__merge(params, { sound })
  }

  return @() builder(stateFlags.value)
}

let Bordered = textButton(fillColor, hdpx(1))

local defaultButton = @(text, handler, params = {}) Bordered(text, handler, params)

let export = class {
  Default = @(_self, text, handler, params = {}) defaultButton(text, handler, params)
  Bordered = @(text, handler, params = {}) Bordered(text, handler, params)
  SmallBordered = @(text, handler, params = {}) Bordered(text, handler, {
    btnHeight = smallBtnHeight
    txtFont = fontMedium
  }.__merge(params))
  FAButton = @(iconId, callBack, params = {})
    Bordered(fa[iconId], callBack, {
      btnWidth = commonBtnHeight
      txtFont = fontFontawesome
    }.__merge(params))
  setDefaultButton = function(buttonCtor) { defaultButton = buttonCtor }
}()

return export
