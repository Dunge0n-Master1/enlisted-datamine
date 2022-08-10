from "%enlSqGlob/ui_library.nut" import *

let {body_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let baseCombo = require("%ui/components/base_combobox.nut")

let {BtnTextHover, comboboxBorderColor, BtnBgActive, BtnBgHover, ControlBgOpaque, Active, Inactive, TextHighlight, TextDefault} = require("%ui/style/colors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {mkImageCompByDargKey} = require("gamepadImgByKey.nut")
let {isGamepad, isTouch} = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")

let borderColor = comboboxBorderColor

let listItemSound = {
  click  = "ui/button_click_inactive"
  hover = "ui/menu_highlight_settings"
  active = "ui/button_action"
}

let function fillColor(sf) {
  if (sf & S_ACTIVE)
    return BtnBgActive
  if (sf & S_HOVER)
    return BtnBgHover
  return ControlBgOpaque
}

let hotkeyLoc = loc("controls/check/toggleOrEnable/prefix", "Toggle")

let function comboStyle(style_params) {
  let function label(params) {
    let sf = params?.sf ?? 0
    local color = Active
    let disabled = params?.disabled ?? false
    if (disabled)
      color = Inactive
    else if (sf & S_HOVER)
      color = BtnTextHover

    let labelText = {
      group = params?.group
      rendObj = ROBJ_TEXT
      //behavior = Behaviors.Marquee
      margin = [fsh(0.5),fsh(1.0),fsh(0.5),fsh(1.0)]
      text = params?.text
      color
      size = [flex(), SIZE_TO_CONTENT]
    }.__update(body_txt)

    let function popupArrow() {
      return !disabled ? {
        size = [ph(100), ph(100)]
        margin = hdpx(3)
        children = {
          rendObj = ROBJ_TEXT
          padding = [hdpx(1), 0, 0, hdpx(2)]
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
        fillColor = fillColor(sf)
        size = flex()
        borderColor = borderColor
        children = [
          label({text=text, sf=sf, group=group, disabled=disabled}),
          sf & S_HOVER ? hotkeysElem : null
        ]
        borderWidth = hdpx(1)
        borderRadius = hdpx(3)
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
      local textColor
      if (is_current)
        textColor = (sf & S_HOVER) ? BtnTextHover : TextHighlight
      else
        textColor = (sf & S_HOVER) ? BtnTextHover : TextDefault

      let bgColor = (sf & S_HOVER) ? BtnBgHover : ControlBgOpaque
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
        padding = [0,hdpx(8),0,hdpx(8)]
        borderWidth = 0
        flow = FLOW_HORIZONTAL
        onClick = action
        onElemState = @(nsf) stateFlags.update(nsf)
        sound = listItemSound

        children = [
          {
            rendObj = ROBJ_TEXT
            margin = fsh(0.5)
            group
            text
            color = textColor
          }.__update(body_txt)
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
      hotkeys = [["^Esc | {0}".subst(JB.B)]]
      //rendObj = ROBJ_FRAME
      //borderWidth = 1
      //color = Active
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
    popupBgColor = ControlBgOpaque
    popupBdColor = borderColor
    popupBorderWidth = hdpx(1)
    dropDir = style_params?.dropDir
    boxCtor
    rootBaseStyle
    listItem
    itemGap = {rendObj=ROBJ_SOLID size=[flex(),hdpx(1)] color=borderColor}
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
