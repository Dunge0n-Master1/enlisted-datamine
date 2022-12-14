from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let colors = require("%ui/style/colors.nut")
let textButtonTextCtor = require("textButtonTextCtor.nut")
let defStyle = require("textButton.style.nut")

let function textColor(sf, style=null, isEnabled = true) {
  let styling = defStyle.__merge(style ?? {})
  if (!isEnabled) return styling.TextDisabled
  if (sf & S_ACTIVE)    return styling.TextActive
  if (sf & S_HOVER)     return styling.TextHover
  if (sf & S_KB_FOCUS)  return styling.TextFocused
  return styling.TextNormal
}

let function borderColor(sf, style=null, isEnabled = true) {
  let styling = defStyle.__merge(style ?? {})
  if (!isEnabled) return styling.BdDisabled
  if (sf & S_ACTIVE)    return styling.BdActive
  if (sf & S_HOVER)     return styling.BdHover
  if (sf & S_KB_FOCUS)  return styling.BdFocused
  return styling.BdNormal
}

let function fillColor(sf, style=null, isEnabled = true) {
  let styling = defStyle.__merge(style ?? {})
  if (!isEnabled) return styling.BgDisabled
  if (sf & S_ACTIVE)    return styling.BgActive
  if (sf & S_HOVER)     return styling.BgHover
  if (sf & S_KB_FOCUS)  return styling.BgFocused
  return styling.BgNormal
}

let function fillColorTransp(sf, style=null, _isEnabled = true) {
  let styling = defStyle.__merge(style ?? {})
  if (sf & S_ACTIVE)    return styling.BgActive
  if (sf & S_HOVER)     return styling.BgHover
  if (sf & S_KB_FOCUS)  return styling.BgFocused
  return 0
}

let defTextCtor = @(text, _params, _handler, _group, _sf) text
let textButton = @(fill_color, border_width) function(text, handler, params={}) {
  let group = ElemGroup()
  let { stateFlags = Watched(0), overrideBySf = null } = params
  let function builder(sf) {
    let paramsExt = overrideBySf == null
      ? params
      : params.__merge(overrideBySf(sf, params?.isEnabled ?? true) ?? {})
    let {
      font = body_txt.font, fontSize = body_txt.fontSize, // TODO bad practice to pass values both as root & textParams fields
      textCtor = defTextCtor, isEnabled = true,
      style = defStyle, textMargin = defStyle.textMargin, key = handler,
      bgChild = null, fgChild = null
    } = paramsExt
    let sound = isEnabled ? paramsExt?.style.sound ?? paramsExt?.sound : null
    return {
      watch = stateFlags
      onElemState = @(v) stateFlags(v)
      margin = defStyle.btnMargin
      key
      group
      rendObj = ROBJ_BOX
      size = SIZE_TO_CONTENT
      fillColor = fill_color(sf, style, isEnabled)
      borderWidth = border_width
      borderRadius = hdpx(4)
      valign = ALIGN_CENTER
      clipChildren = true
      borderColor = borderColor(sf, style, isEnabled)
      onDetach = @() stateFlags(0)

      children = [
        bgChild
        textCtor({
          rendObj = ROBJ_TEXT
          text = (type(text)=="function") ? text() : text
          scrollOnHover=true
          delay = 0.5
          speed = [hdpx(100),hdpx(700)]
          maxWidth = pw(100)
          ellipsis = false
          margin = textMargin
          font
          fontSize
          group
          behavior = [Behaviors.Marquee]
          color = textColor(sf, style, isEnabled)
        }.__update(paramsExt?.textParams ?? {}), paramsExt, handler, group, sf)
        fgChild
      ]

      behavior = Behaviors.Button
      onClick = isEnabled ? handler : null
    }.__merge(paramsExt, { sound })
  }

  return @() builder(stateFlags.value)
}
let soundDefault = {
  click  = "ui/enlist/button_click"
  hover  = "ui/enlist/button_highlight"
}

let soundActive = soundDefault.__merge({  active = "ui/enlist/button_action" })

let override = {
  halign = ALIGN_CENTER
  sound = soundActive
  textCtor = textButtonTextCtor
}.__update(body_txt)

let onlinePurchaseStyle = {
  borderWidth = hdpx(1)

  style = {
    BgNormal = colors.BtnActionBgNormal
    BgActive   = colors.BtnActionBgActive
    BgFocused  = colors.BtnActionBgFocused

    BdNormal  = colors.BtnActionBdNormal
    BdActive   = colors.BtnActionBdActive
    BdFocused = colors.BtnActionBdFocused

    TextNormal  = colors.BtnActionTextNormal
    TextActive  = colors.BtnActionTextActive
    TextFocused = colors.BtnActionTextFocused
    TextHilite  = colors.BtnActionTextHilite
  }
}.__update(body_txt, override)

let primaryButtonStyle = override.__merge({
  style = {
    BgNormal = 0xfa0182b5
    BgActive   = 0xfa015ea2
    BgFocused  = 0xfa0982ca

    TextNormal  = Color(180, 180, 180, 180)
    TextActive  = Color(120, 120, 120, 120)
    TextFocused = Color(160, 160, 160, 120)
    TextHilite  = Color(220, 220, 220, 160)
  }
})

let loginBtnStyle = (clone onlinePurchaseStyle)

let smallStyle = {
  textMargin = [hdpx(3), hdpx(5)]
}.__update(sub_txt)

let Transp = textButton(fillColorTransp, 0)
let Bordered = textButton(fillColor, hdpx(1))
let Flat = textButton(fillColor, 0)

local defaultButton = @(text, handler, params = {}) Bordered(text, handler, override.__merge(params))

let export = class {
  _call = @(_self, text, handler, params = {}) defaultButton(text, handler, params)
  Transp = @(text, handler, params = {}) Transp(text, handler, override.__merge(params))
  Bordered = @(text, handler, params = {}) Bordered(text, handler, override.__merge(params))
  Small = @(text, handler, params = {}) Transp(text, handler, override.__merge(sub_txt, {margin=hdpx(1) textMargin=[hdpx(2),hdpx(5),hdpx(2),hdpx(5)]}, params))
  SmallBordered = @(text, handler, params = {}) Bordered(text, handler, override.__merge(smallStyle, params))
  Flat = @(text, handler, params = {}) Flat(text, handler, override.__merge(params))
  SmallFlat = @(text, handler, params = {})
    Flat(text, handler, override.__merge(smallStyle, params))
  FAButton = @(iconId, callBack, params = {})
    Flat(fa[iconId], callBack, {
      size = [hdpx(40), hdpx(40)]
      halign = ALIGN_CENTER
      rendObj = ROBJ_INSCRIPTION
      borderWidth = (params?.isEnabled ?? true) ? hdpx(1):0
      margin = hdpx(1)
      sound = (params?.isEnabled ?? true) ? soundDefault : null
    }.__merge(fontawesome, params))

  Purchase = @(text, handler, params = {}) Bordered(text, handler, body_txt.__merge(onlinePurchaseStyle, params))
  PrimaryFlat = @(text, handler, params = {}) Flat(text, handler, body_txt.__merge(primaryButtonStyle, params))

  onlinePurchaseStyle = onlinePurchaseStyle
  primaryButtonStyle = primaryButtonStyle
  smallStyle = smallStyle
  override = override
  loginBtnStyle = loginBtnStyle

  setDefaultButton = function(buttonCtor) { defaultButton = buttonCtor }
  soundDefault = soundDefault
  soundActive = soundActive
}()

return export
