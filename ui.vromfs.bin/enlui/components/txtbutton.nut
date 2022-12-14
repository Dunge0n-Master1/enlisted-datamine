from "%enlSqGlob/ui_library.nut" import *

let { fontFontawesome, fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { disabledTxtColor, defTxtColor, titleTxtColor, commonBtnHeight, smallBtnHeight, panelBgColor,
  defBdColor, commonBorderRadius, midPadding, hoverTxtColor, hoverBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let getGamepadHotkeys = require("%ui/components/getGamepadHotkeys.nut")
let {mkImageCompByDargKey} = require("%ui/components/gamepadImgByKey.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { soundActive } = require("%ui/components/textButton.nut")

let defTxtStyle = {
  defTxtColor
  hoverTxtColor = titleTxtColor
  activeTxtColor = titleTxtColor
  disabledTxtColor
}

let function textColor(sf, style = {}, isEnabled = true) {
  let txtColor = defTxtStyle.__merge(style)
  if (!isEnabled) return txtColor.disabledTxtColor
  if (sf & S_ACTIVE) return txtColor.activeTxtColor
  if (sf & S_HOVER)     return txtColor.hoverTxtColor
  if (sf & S_KB_FOCUS)  return txtColor.hoverTxtColor
  return txtColor.defTxtColor
}


let pressedBtnStyle = {
  defTxtColor = titleTxtColor
  hoverTxtColor = hoverTxtColor
  defBgColor = panelBgColor
  hoverBgColor = hoverBgColor
}


let defBorderStyle = {
  disabledBdColor = disabledTxtColor
  defBdColor
  hoverBdColor = titleTxtColor
  activeBdColor = titleTxtColor
}

let function borderColor(sf, style = {}, isEnabled = true) {
  let bdColor = defBorderStyle.__merge(style)
  if (!isEnabled)       return bdColor.disabledBdColor
  if (sf & S_ACTIVE)    return bdColor.activeBdColor
  if (sf & S_HOVER)     return bdColor.hoverBdColor
  if (sf & S_KB_FOCUS)  return bdColor.hoverBdColor
  return bdColor.defBdColor
}


let defBgStyle = {
  defBgColor = null
  hoverBgColor = null
  activeBgColor = panelBgColor
  disabledBgColor = null
}


let function fillColor(sf, style = {}, isEnabled = true) {
  let bgColor = defBgStyle.__merge(style)
  if (!isEnabled)       return bgColor.disabledBgColor
  if (sf & S_ACTIVE)    return bgColor.activeBgColor
  if (sf & S_HOVER)     return bgColor.hoverBgColor
  if (sf & S_KB_FOCUS)  return bgColor.hoverBgColor
  return bgColor.defBgColor
}


let defHotkeyParams = {
  hplace = ALIGN_LEFT
  margin = midPadding
}

let textButton = @(fill_color, border_width) function(text, handler, params={}) {
  let group = ElemGroup()
  let { stateFlags = Watched(0) } = params
  let {
    txtFont = fontLarge, isEnabled = true, style = {}, bgChild = null, fgChild = null,
    btnHeight = commonBtnHeight, btnWidth = null, sound = {}, hint = null
  } = params
  let minWidth = btnWidth ?? SIZE_TO_CONTENT
  let function builder(sf) {
    local gamepadHotkey = getGamepadHotkeys(params?.hotkeys)
    local gamepadBtn = null

    if (gamepadHotkey != "") {
      if ((sf & S_HOVER) != 0 || (sf & S_ACTIVE) != 0)
        gamepadHotkey = JB.A
      gamepadBtn = mkImageCompByDargKey(gamepadHotkey
        defHotkeyParams.__merge({ height = txtFont.fontSize}, params?.hotkeyParams ?? {}))
    }

    return {
      watch = [stateFlags, isGamepad]
      rendObj = ROBJ_BOX
      fillColor = fill_color(sf, style, isEnabled)
      borderWidth = border_width
      borderRadius = commonBorderRadius
      borderColor = borderColor(sf, style, isEnabled)
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
      onHover = @(on) hint == null ? null : setTooltip(!on ? null : tooltipCtor(hint))
      onClick = isEnabled ? handler : null
      sound = soundActive.__update(sound)

      children = [
        isGamepad.value ? gamepadBtn : null
        bgChild
        {
          rendObj = ROBJ_TEXT
          text = (type(text)=="function") ? text() : text
          color = textColor(sf, style, isEnabled)
          margin = [fsh(1), fsh(3)]
          group
        }.__update(txtFont)
        fgChild
      ]
    }.__merge(params)
  }

  return @() builder(stateFlags.value)
}

let Bordered = textButton(fillColor, hdpx(1))
let Flat = textButton(fillColor, 0)

local defaultButton = @(text, handler, params = {}) Bordered(text, handler, params)

let export = class {
  Default = @(_self, text, handler, params = {}) defaultButton(text, handler, params)
  Bordered = @(text, handler, params = {}) Bordered(text, handler, params)
  SmallBordered = @(text, handler, params = {}) Bordered(text, handler, {
    btnHeight = smallBtnHeight
    txtFont = fontMedium
  }.__merge(params))
  PressedBordered = @(text, handler, params = {}) Bordered(text, handler, {
    style = pressedBtnStyle
  }.__merge(params))
  FAButton = @(iconId, callBack, params = {}) function() {
    let icon = isGamepad.value && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = Bordered(icon, callBack, {
          btnWidth = commonBtnHeight
          txtFont = fontFontawesome
        }.__merge(params))
    }
  }
  FAFlatButton = @(iconId, callBack, params = {}) function() {
    let icon = isGamepad.value && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = Flat(icon, callBack, {
          btnWidth = commonBtnHeight
          txtFont = fontFontawesome
        }.__merge(params))
    }
  }
  setDefaultButton = function(buttonCtor) { defaultButton = buttonCtor }
}()

return export
