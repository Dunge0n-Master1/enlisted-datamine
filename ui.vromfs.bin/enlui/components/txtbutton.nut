from "%enlSqGlob/ui_library.nut" import *

let { fontFontawesome, fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { disabledTxtColor, defTxtColor, titleTxtColor, commonBtnHeight, smallBtnHeight, defBdColor,
  commonBorderRadius, midPadding, hoverTxtColor, hoverPanelBgColor, accentColor, darkTxtColor,
  darkPanelBgColor, brightAccentColor, hoverSlotBgColor
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
  hoverTxtColor = darkTxtColor
  activeTxtColor = defTxtColor
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
  defBgColor = darkPanelBgColor
  hoverBgColor = hoverPanelBgColor
}


let accentBtnStyle = {
  defTxtColor = darkTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = darkTxtColor
  defBgColor = brightAccentColor
  hoverBgColor = accentColor
  activeBgColor = 0xFFB4B4B4
}


let defBorderStyle = {
  disabledBdColor = disabledTxtColor
  defBdColor
  hoverBdColor = titleTxtColor
  activeBdColor = titleTxtColor
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
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
  hoverBgColor = hoverSlotBgColor
  activeBgColor = darkPanelBgColor
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


let defButtonBg = @(sf, style, isEnabled) {
  size = flex()
  rendObj = style?.rendObj ?? ROBJ_BOX
  fillColor = fillColor(sf, style, isEnabled)
  borderWidth = style?.borderWidth ?? defBorderStyle.borderWidth
  borderRadius = style?.borderRadius ?? defBorderStyle.borderRadius
  borderColor = borderColor(sf, style, isEnabled)
}


let function textButton (text, handler, params={}) {
  let group = ElemGroup()
  let { stateFlags = Watched(0) } = params
  let {
    txtParams = fontLarge, isEnabled = true, style = {}, bgComp = null, fgChild = null,
    btnHeight = commonBtnHeight, btnWidth = null, sound = {}, hint = null, onHoverFunc = null
  } = params
  let minWidth = btnWidth ?? SIZE_TO_CONTENT
  let function builder(sf) {
    local gamepadHotkey = getGamepadHotkeys(params?.hotkeys)
    local gamepadBtn = null

    if (gamepadHotkey != "") {
      if ((sf & S_HOVER) != 0 || (sf & S_ACTIVE) != 0)
        gamepadHotkey = JB.A
      gamepadBtn = mkImageCompByDargKey(gamepadHotkey
        defHotkeyParams.__merge({ height = txtParams.fontSize}, params?.hotkeyParams ?? {}))
    }
    let bgChild = bgComp?(sf, isEnabled) ?? defButtonBg(sf, style, isEnabled)
    return {
      watch = [stateFlags, isGamepad]
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
      onHover = function(on) {
        onHoverFunc?(on)
        if (hint != null)
          setTooltip(!on ? null : tooltipCtor(hint))
      }
      onClick = isEnabled ? handler : null
      sound = soundActive.__update(sound)

      children = [
        bgChild
        isGamepad.value ? gamepadBtn : null
        {
          rendObj = ROBJ_TEXT
          text = (type(text)=="function") ? text() : text
          color = textColor(sf, style, isEnabled)
          margin = [fsh(1), fsh(3)]
          group
        }.__update(txtParams)
        fgChild
      ]
    }.__merge(params)
  }

  return @() builder(stateFlags.value)
}


local defaultButton = @(text, handler, params = {}) textButton(text, handler, params)

let export = class {
  Default = @(_self, text, handler, params = {}) defaultButton(text, handler, params)
  Bordered = @(text, handler, params = {}) textButton(text, handler, params)
  Flat = @(text, handler, params = {}) textButton(text, handler, {
    style = { borderWidth = 0 }
  }.__merge(params))
  SmallBordered = @(text, handler, params = {}) textButton(text, handler, {
    btnHeight = smallBtnHeight
    txtParams = fontMedium
  }.__merge(params))
  PressedBordered = @(text, handler, params = {}) textButton(text, handler, {
    style = pressedBtnStyle
  }.__merge(params))
  FAButton = @(iconId, handler, params = {}) function() {
    let icon = isGamepad.value && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = textButton(icon, handler, {
          btnWidth = commonBtnHeight
          txtParams = fontFontawesome
        }.__merge(params))
    }
  }
  FAFlatButton = @(iconId, handler, params = {}) function() {
    let icon = isGamepad.value && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = textButton(icon, handler, {
          btnWidth = commonBtnHeight
          txtParams = fontFontawesome
          style = { borderWidth = 0 rendObj = ROBJ_WORLD_BLUR_PANEL }
        }.__merge(params))
    }
  }
  Accented = @(text, handler, params = {}) textButton(text, handler, {
    style = { borderWidth = 0 }.__merge(accentBtnStyle)
  }.__merge(params))
  setDefaultButton = function(buttonCtor) { defaultButton = buttonCtor }
}()

return export
