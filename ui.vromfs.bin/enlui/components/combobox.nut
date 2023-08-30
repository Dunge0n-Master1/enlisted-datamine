from "%enlSqGlob/ui_library.nut" import *

let {fontBody, fontawesome} = require("%enlSqGlob/ui/fontsStyle.nut")
let baseCombo = require("%ui/components/base_combobox.nut")

let {BtnTextHover, comboboxBorderColor, BtnBgActive, BtnBgHover, ControlBgOpaque, Active, Inactive, TextHighlight, TextDefault} = require("%ui/style/colors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {mkImageCompByDargKey} = require("gamepadImgByKey.nut")
let {isGamepad, isTouch} = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")

let listItemSound = {
  click  = "ui/button_click_inactive"
  hover = "ui/menu_highlight_settings"
  active = "ui/button_action"
}

let defaultStyle = freeze({
  borderColor     = comboboxBorderColor
  borderWidth     = hdpx(1)
  borderRadius    = hdpx(3)
  fillColorActive = BtnBgActive
  fillColorHover  = BtnBgHover
  fillColor       = ControlBgOpaque
  color           = Active
  colorDisabled   = Inactive
  colorHover      = BtnTextHover
  liColor         = TextDefault
  liColorCurrent  = TextHighlight
  liColorHover    = BtnTextHover
  liPadding       = [0, hdpx(8)]
  liMargin        = fsh(0.5)
  labelMargin     = [fsh(0.5),fsh(1.0)]
  arrowMargin     = hdpx(3)
  arrowPadding    = [hdpx(1), 0, 0, hdpx(2)]
  gapSize         = hdpx(1)
})

let function fillColor(sf, style) {
  if (sf & S_ACTIVE)
    return style.fillColorActive
  if (sf & S_HOVER)
    return style.fillColorHover
  return style.fillColor
}

let hotkeyLoc = loc("controls/check/toggleOrEnable/prefix", "Toggle")

let function comboStyle(style_params) {
  let style = defaultStyle.__merge(style_params?.style ?? {})

  let function label(params) {
    let sf = params?.sf ?? 0
    local color = style.color
    let disabled = params?.disabled ?? false
    if (disabled)
      color = style.colorDisabled
    else if (sf & S_HOVER)
      color = style.colorHover

    let labelText = {
      group = params?.group
      rendObj = ROBJ_TEXT
      //behavior = Behaviors.Marquee
      margin = style.labelMargin
      text = params?.text
      color
      size = [flex(), SIZE_TO_CONTENT]
    }.__update(fontBody)

    let function popupArrow() {
      return !disabled ? {
        size = [ph(100), ph(100)]
        margin = style.arrowMargin
        children = {
          rendObj = ROBJ_TEXT
          padding = style.arrowPadding
          text = isGamepad.value ? fa["caret-right"] : fa["caret-down"]
          color
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }.__update(fontawesome)
      } : null
    }

    return {
      size = flex()
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        labelText
        popupArrow
      ]
    }
  }


  let function boxCtor(params) {
    let {comboOpen, disabled, text, stateFlags, group} = params
    let toggle = @() comboOpen(!comboOpen.value)
    let hotkeysElem = style_params?.useHotkeys ? {
      key = "hotkeys"
      hotkeys = [
        ["Left | J:D.Left", hotkeyLoc, toggle],
        ["Right | J:D.Right", hotkeyLoc, toggle],
      ]
    } : null

    return function() {
      let sf = stateFlags.value
      return{
        rendObj = ROBJ_BOX
        fillColor = fillColor(sf, style)
        size = flex()
        borderColor = style.borderColor
        children = [
          label({text=text, sf=sf, group=group, disabled=disabled}),
          sf & S_HOVER ? hotkeysElem : null
        ]
        borderWidth = style.borderWidth
        borderRadius = style.borderRadius
        watch = stateFlags
        margin = 0
      }
    }
  }

  let function listItem(text, action, is_current, params = null) {
    let group = ElemGroup()
    let stateFlags = Watched(0)

    return function() {
      let sf = stateFlags.value
      let textColor = sf & S_HOVER ? style.colorHover
        : is_current ? style.liColorCurrent
        : style.liColor
      let bgColor = sf & S_HOVER ? style.fillColorHover : style.fillColor
      let hotkey_hint = (sf & S_HOVER) && isGamepad.value
        ? mkImageCompByDargKey(JB.A, {hplace = ALIGN_RIGHT vplace = ALIGN_CENTER}) : null

      return {
        behavior = [Behaviors.Button, Behaviors.Marquee]
        xmbNode = params?.xmbNode
        scrollOnHover=true
        eventPassThrough = isTouch.value
        speed =[hdpx(100),hdpx(1000)]
        delay =0.5
        size = [flex(), SIZE_TO_CONTENT]
        group = group
        watch = [stateFlags, isGamepad]

        rendObj = ROBJ_BOX
        fillColor = bgColor
        padding = style.liPadding
        borderWidth = 0
        flow = FLOW_HORIZONTAL
        onClick = action
        onElemState = @(nsf) stateFlags.update(nsf)
        sound = listItemSound

        children = [
          {
            rendObj = ROBJ_TEXT
            margin = style.liMargin
            group
            text
            color = textColor
          }.__update(fontBody)
          {size = [flex(),0]}
          hotkey_hint
        ]
      }
    }
  }


  let function closeButton(onClick) {
    return {
      size = flex()
      behavior = Behaviors.Button
      onClick
      hotkeys = [[$"^{JB.B} | Esc"]]
    }
  }

  let function onOpenDropDown(itemXmbNode) {
    gui_scene.setXmbFocus(isGamepad.value ? itemXmbNode : null)
  }

  let function onCloseDropDown(boxXmbNode) {
    if (isGamepad.value)
      gui_scene.setXmbFocus(boxXmbNode)
  }

  let rootBaseStyle = {
    sound = buttonSound
  }

  return {
    popupBgColor = style.fillColor
    popupBdColor = style.borderColor
    popupBorderWidth = style.borderWidth
    dropDir = style_params?.dropDir
    boxCtor
    rootBaseStyle
    listItem
    itemGap = {
      rendObj = ROBJ_SOLID
      size = [flex(), style.gapSize]
      color = style.borderColor
    }
    closeButton
    onOpenDropDown
    onCloseDropDown
  }
}


let function combo(wdata, options, style_params) {
  return baseCombo(wdata, options, comboStyle(style_params))
}

let export = class{
  //Big = combo(wdata, options)
  _call = @(_self, wdata, options, style_params={}) combo(wdata, options, style_params)
}()

return export
