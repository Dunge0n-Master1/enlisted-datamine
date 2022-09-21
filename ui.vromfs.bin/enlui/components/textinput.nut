from "%enlSqGlob/ui_library.nut" import *
from "string" import split_by_chars

let colors = require("%ui/style/colors.nut")
let { isStringInteger, isStringFloat, isStringLatin } = require("%sqstd/string.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let { defTxtColor, activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")

let logPrefix = "[TextInput] "
let { logerr } = require("dagor.debug")

let CHAR_MASK_TYPES = {
  lat = {
    regMask = "a-z,A-Z"
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  }
  integer = {
    regMask = "0-9"
    chars = "0123456789"
  }
  symbol = {
    regMask = "!#$%&'*+-/=?^_`{|}~"
    chars = "!#$%&'*+-/=?^_`{|}~"
  }
}

let function getCharMaskTypes(reqTypes) {
  if (typeof reqTypes != "string")
    return []

  let types = []
  reqTypes.split("; ").each(function(t) {
    if (t in CHAR_MASK_TYPES)
      types.append(CHAR_MASK_TYPES[t])
    else
      logerr($"{logPrefix}wrong char mask type {t}")
  })

  return types
}

let function isStringLikelyEmail(str, _verbose=true) {
// this check is not rfc fully compatible. We check that @ exist and correctly used, and that let and domain parts exist and they are correct length.
// Domain part also have at least one period and main domain at least 2 symbols
// also come correct emails on google are against RFC, for example a.a.a@gmail.com.

  if (type(str)!="string")
    return false
  let splitted = split_by_chars(str,"@")
  if (splitted.len()<2)
    return false
  local locpart = splitted[0]
  if (splitted.len()>2)
    locpart = "@".join(splitted.slice(0,-1))
  if (locpart.len()>64)
    return false
  let dompart = splitted[splitted.len()-1]
  if (dompart.len()>253 || dompart.len()<4) //RFC + domain should be at least x.xx
    return false
  let quotes = locpart.indexof("\"")
  if (quotes && quotes!=0)
    return false //quotes only at the begining
  if (quotes==null && locpart.indexof("@")!=null)
    return false //no @ without quotes
  if (dompart.indexof(".")==null || dompart.indexof(".")>dompart.len()-3) // warning disable: -func-can-return-null
    return false  //too short first level domain or no periods
  return true
}

let function defaultFrame(inputObj, group, sf) {
  return {
    rendObj = ROBJ_FRAME
    borderWidth = [hdpx(1), hdpx(1), 0, hdpx(1)]
    size = [flex(), SIZE_TO_CONTENT]
    color = (sf & S_KB_FOCUS) ? Color(180, 180, 180) : Color(120, 120, 120)
    group = group

    children = {
      rendObj = ROBJ_FRAME
      borderWidth = [0, 0, hdpx(1), 0]
      size = [flex(), SIZE_TO_CONTENT]
      color = (sf & S_KB_FOCUS) ? Color(250, 250, 250) : Color(180, 180, 180)
      group = group

      children = inputObj
    }
  }
}

let function isValidStrByType(str, inputType) {
  if (str=="")
    return true
  if (inputType=="mail")
     return isStringLikelyEmail(str)
  if (inputType=="num")
     return isStringInteger(str) || isStringFloat(str)
  if (inputType=="integer")
     return isStringInteger(str)
  if (inputType=="float")
     return isStringFloat(str)
  if (inputType=="lat")
     return isStringLatin(str)
  return true
}

let defaultColors = {
  placeHolderColor = Color(80, 80, 80, 80)
  textColor = Color(255,255,255)
  backGroundColor = Color(28, 28, 28, 150)
  highlightFailure = Color(255,60,70)
}


let failAnim = @(trigger) {
  prop = AnimProp.color
  from = defaultColors.highlightFailure
  easing = OutCubic
  duration = 1.0
  trigger = trigger
}

let interactiveValidTypes = ["num","lat","integer","float"]

let function textInput(text_state, options={}, frameCtor=defaultFrame) {
  let group = ElemGroup()
  let {
    setValue = @(v) text_state(v), inputType = null,
    placeholder = null, showPlaceHolderOnFocus = false, password = null, maxChars = null,
    title = null, font = null, fontSize = null, hotkeys = null,
    size = [flex(), fontH(100)], textmargin = [sh(1), sh(0.5)], valignText = ALIGN_BOTTOM,
    margin = [sh(1), 0], padding = 0, borderRadius = hdpx(3), valign = ALIGN_CENTER,
    xmbNode = null, imeOpenJoyBtn = null, charMaskTypes = null,

    //handlers
    onBlur = null, onReturn = null,
    onEscape = @() set_kb_focus(null), onChange = null, onFocus = null, onAttach = null,
    onHover = null, onImeFinish = null
  } = options

  local {
    isValidResult = null, isValidChange = null, hintText = ""
  } = options

  let rcolors = defaultColors.__merge(options?.colors ?? {})
  let cmTypes = getCharMaskTypes(charMaskTypes)

  local cmRegExp = ", ".join(cmTypes.map(@(t) t.regMask), true)
  local charMask = "".join(cmTypes.map(@(t) t.chars))

  let stateFlags = Watched(0)

  let function isValidChangeExt(new_val) {
    return isValidChange?(new_val)
      || interactiveValidTypes.indexof(inputType) == null
      || isValidStrByType(new_val, inputType)
  }

  let function isValidResultExt(new_val) {
    return isValidResult?(new_val)
      || isValidStrByType(new_val, inputType)
  }

  let function onBlurExt() {
    if (!isValidResultExt(text_state.value))
      anim_start(text_state)
    onBlur?()
  }

  let function onReturnExt() {
    if (!isValidResultExt(text_state.value))
      anim_start(text_state)
    onReturn?()
  }

  let function onEscapeExt() {
    if (!isValidResultExt(text_state.value))
      anim_start(text_state)
    onEscape()
  }

  let function onChangeExt(new_val) {
    onChange?(new_val)
    if (!isValidChangeExt(new_val))
      anim_start(text_state)
    else
      setValue(new_val)
  }

  let function onWrongInput() {
    anim_start(text_state)
  }

  let function onHoverExt(on) {
    if (onHover) {
      onHover(on)
      return
    }

    let charMaskHint = cmRegExp == "" ? "" : loc("options/password/charMaskHint", { symbols = colorize(activeTxtColor, cmRegExp) })
    let hint = hintText == "" ? charMaskHint : "\n".concat(charMaskHint, hintText)

    setTooltip(on && hint != ""
      ? tooltipBox({
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = defTxtColor
          text = hint
        }.__update(sub_txt))
      : null)
  }

  local placeholderObj = null
  if (placeholder != null) {
    let phBase = {
      text = placeholder
      rendObj = ROBJ_TEXT
      font
      fontSize
      color = rcolors.placeHolderColor
      animations = [failAnim(text_state)]
      margin = [0, sh(0.5)]
    }
    placeholderObj = placeholder instanceof Watched
      ? @() phBase.__update({ watch = placeholder, text = placeholder.value })
      : phBase
  }

  let inputObj = @() {
    watch = [text_state, stateFlags]
    rendObj = ROBJ_TEXT
    behavior = Behaviors.TextInput

    size
    font
    fontSize
    color = rcolors.textColor
    group
    margin = textmargin
    valign = valignText

    animations = [failAnim(text_state)]

    text = text_state.value
    title
    inputType = inputType
    password = password
    key = text_state

    maxChars
    hotkeys
    charMask

    onChange = onChangeExt

    onFocus
    onBlur   = onBlurExt
    onAttach
    onReturn = onReturnExt
    onEscape = onEscapeExt
    onHover = onHoverExt
    onImeFinish
    onWrongInput
    xmbNode
    imeOpenJoyBtn

    children = (text_state.value?.len() ?? 0)== 0
        && (showPlaceHolderOnFocus || !(stateFlags.value & S_KB_FOCUS))
      ? placeholderObj
      : null
  }

  return @() {
    watch = [stateFlags]
    onElemState = @(sf) stateFlags(sf)
    margin
    padding

    rendObj = ROBJ_BOX
    fillColor = rcolors.backGroundColor
    borderWidth = 0
    borderRadius
    clipChildren = true
    size = [flex(), SIZE_TO_CONTENT]
    group
    animations = [failAnim(text_state)]
    valign

    children = frameCtor(inputObj, group, stateFlags.value)
  }
}



let function makeFrame(inputObj, group, sf) {
  let isHover = sf & S_HOVER
  let isKbdFocus = sf & S_KB_FOCUS
  return {
    rendObj = ROBJ_BOX
    borderWidth = [hdpx(1), hdpx(1), 0, hdpx(1)]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    borderColor = isHover ? colors.InputFrameLtHovered
                : isKbdFocus ? colors.InputFrameLtFocused
                : colors.InputFrameLt
    group = group
    children = {
      rendObj = ROBJ_BOX
      borderWidth = [0, 0, hdpx(1), 0]
      margin =[0,hdpx(1)]
      fillColor = 0
      size = [flex(), SIZE_TO_CONTENT]
      borderColor = isHover ? colors.InputFrameRbHovered
                : isKbdFocus ? colors.InputFrameRbFocused
                : colors.InputFrameRb
      group = group

      children = inputObj
    }
  }
}


let function makeUnderline(inputObj, group, sf) {
  let isHover = sf & S_HOVER
  let isKbdFocus = sf & S_KB_FOCUS
  return {
    rendObj = ROBJ_BOX
    borderWidth = [0, 0, hdpx(1), 0]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    group = group
    borderColor = isHover ? colors.InputFrameRbHovered
              : isKbdFocus ? colors.InputFrameRbFocused
              : colors.InputFrameRb
    children = inputObj
  }
}


let function noFrame(inputObj, _group, _sf) {
  return inputObj
}


let textInputColors = {
  placeHolderColor = Color(80,80,80,80)
  textColor = colors.Active
  backGroundColor = colors.ControlBg
}


let makeTextInput = @(text_state, options, frameCtor)
  textInput(text_state,
    options.__merge({ colors = textInputColors }),
    frameCtor)


let export = class{
  Framed = @(text_state, options={}) makeTextInput(text_state, options, makeFrame)
  Underlined = @(text_state, options={}) makeTextInput(text_state, options, makeUnderline)
  NoFrame = @(text_state, options={}) makeTextInput(text_state, options, noFrame)
  _call = @(_self, text_state, options={}) makeTextInput(text_state, options, makeFrame)
}()


return export
