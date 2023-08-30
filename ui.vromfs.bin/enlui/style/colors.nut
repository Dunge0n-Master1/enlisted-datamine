from "%enlSqGlob/ui_library.nut" import *

let { format, hexStringToInt } =  require("string").__merge(require("%sqstd/string.nut"))

let TextHighLight = Color(220, 220, 220, 160)
let WindowHeader = Color(30,30,40,150)
let colors = {
  comboboxBorderColor = Color(60,60,60,255)
  UnseenIcon = Color(20, 255, 10)
  UnseenGlow = Color(0, 0, 0, 255)
  Black = Color(0, 0, 0, 255)
  FullTransparent = Color(0, 0, 0, 0)
  ScrollBgColor = Color(3, 9, 12, 150)

  CheckBoxContentDefault = Color(180, 180, 180)
  CheckBoxContentHover = Color(255, 255, 255)
  CheckBoxContentActive = Color(240, 240, 240, 160)

  TextActive    = Color(160, 160, 160, 160)
  TextDefault   = Color(120, 120, 120, 160)
  TextInactive  = Color(80, 80, 80, 160)
  TextHighlight = TextHighLight
  TextHover     = TextHighLight
  MsgMarkedText = 0xfff9db78

  ModalBgTint   = Color(10, 10, 10, 120)
  MenuBgOverlay = Color(0, 0, 0, 200)
  WindowColor   = Color(0, 0, 0, 200)
  WindowBlurredColor  = Color(30,30,40,150)

  // options/controls menu row backgrounds
  BtnBgNormal     = Color(0,0,0,200)
  BtnBgHoverLite  = Color(10,10,10,200)
  BtnBgHover      = Color(220, 220, 220, 200)
  BtnBgActive     = Color(180, 180, 180, 180)
  BtnBgFocused    = Color(40, 40, 40, 120)
  BtnBgSelected   = Color(150,150,150)
  BtnBgDisabled   = Color(20, 20, 20, 170)

  BtnBdDisabled  = Color(30, 30, 30, 40)
  BtnBdNormal  = Color(60, 60, 60, 40)
  BtnBdHover    = Color(230, 230, 120, 200)
  BtnBdActive   = Color(220, 220, 220, 180)
  BtnBdFocused = Color(160, 160, 160, 120)

  BtnTextNormal          = Color(160, 160, 160, 120)
  BtnTextHover           = Color(0,0,0)
  BtnTextActive          = Color(0,0,0)
  BtnTextFocused         = Color(160, 160, 160, 120)
  BtnTextHilite          = Color(220, 220, 220, 160)
  BtnTextVisualDisabled  = Color(100, 100, 100, 60)

  BtnActionBgNormal = Color(230, 130, 0, 255)
//  BtnActionBgHover = Color(250,160,0,250)
  BtnActionBgActive   = Color(200, 100, 0, 200)
  BtnActionBgFocused  = Color(250, 160, 20, 255)
  BtnActionBgDisabled = Color(110, 110, 110)

  BtnActionBdNormal  = Color(250,180,80,250)
// BdHover    = Color(250,200,120,250)
  BtnActionBdActive   = Color(250,130,0,250)
  BtnActionBdFocused = Color(250,130,0,250)

  BtnActionTextNormal  = Color(180, 180, 180, 180)
//  BtnActionTextHover   = Color(255, 255, 255, 255)
  BtnActionTextActive  = Color(120, 120, 120, 120)
  BtnActionTextFocused = Color(160, 160, 160, 120)
  BtnActionTextHilite  = Color(220, 220, 220, 160)

  HighlightFailure = Color(255,60,70)

  HoverItemBg = Color(110, 120, 140, 80)
  SelectedItemBg = Color(110, 120, 140, 160)
  ItemIncludeIconBg = Color(70, 70, 70, 220)

  InputFrameLt = Color(120, 120, 120)
  InputFrameRb = Color(180, 180, 180)
  InputFrameLtFocused = Color(180, 180, 180)
  InputFrameRbFocused = Color(250, 250, 250)
  InputFrameRbHovered = Color(255, 255, 255)
  InputFrameLtHovered = Color(240, 240, 240)

  ControlBg = Color(28, 28, 28, 150)
  ControlBgOpaque = Color(28, 28, 28, 240)
  ControlBgTransparent = Color(0, 0, 0, 70)

  progressBarBg = Color(0, 0, 0, 200)
  progressBarFg = Color(50, 135, 30)
  progressBarBorder = TextHighLight

  // ********** Enlist legacy begin *******************
  Active = Color(255,255,255)
  Inactive = Color(160, 160, 160)
  Alert = Color(255,205,80,220)

  WindowBg = Color(0, 0, 0, 220)
  WindowBd = Color(80, 80, 80, 20)
  WindowTransparent = Color(10, 10, 10, 220)
  WindowOpaque = Color(18, 18, 18, 255)
  WindowBlur = Color(100,100,100,255)
  WindowContacts = Color(18,18,18,50)
  WindowHeader = WindowHeader
  HeaderOverlay = WindowHeader

  Interactive = Color(110, 120, 140, 160)
  ButtonActive = Color(100, 120, 200, 120)
  ButtonHover = Color(110, 110, 150, 50)
  ButtonFocused = Color(130, 130, 150, 120)
  // ********** Enlist legacy end ***************
  ItemAmountRoundedBg    = Color(40, 55, 75, 200)

  statusIconBg               = Color(0, 0, 0, 120)

  ContactLeader = Color(170,170,50,205)
  ContactOffline = Color(50,50,50,50)
  ContactReady = Color(50,90,50,50)
  ContactNotReady = Color(90,30,30,60)
  ContactInBattle = Color(90,30,30,60)

  DisabledButtonStyle = {
    style = {
      BgNormal  = Color(150, 150, 150)
      BgActive  = Color(150, 150, 150)
      BgFocused = Color(200, 200, 200)

      BdNormal  = Color(150, 150, 150)
      BdActive  = Color(150, 150, 150)
      BdFocused = Color(200, 200, 200)

      TextNormal  = Color(0, 0, 0, 255)
      TextActive  = Color(0, 0, 0, 255)
      TextFocused = Color(0, 0, 0, 255)
      TextHilite  = Color(0, 0, 0, 255)
    }
  }

  UserNameColor = Color(150, 255, 160, 120)
}

colors.__update({
  textColor = function(sf, isEqupped, defColor = colors.BtnTextNormal) {
    if (isEqupped || (sf & S_ACTIVE))  return colors.BtnTextActive
    if (sf & S_HOVER)                  return colors.BtnTextHover
    if (sf & S_KB_FOCUS)               return colors.BtnTextFocused
    return defColor
  }

  borderColor = function(sf, isEqupped, defColor = colors.BtnBdNormal) {
    if (isEqupped || (sf & S_ACTIVE))  return colors.BtnBdActive
    if (sf & S_HOVER)                  return colors.BtnBdHover
    if (sf & S_KB_FOCUS)               return colors.BtnBdFocused
    return defColor
  }

  fillColor = function(sf, isEqupped, defColor = colors.BtnBgNormal) {
    if (isEqupped || (sf & S_ACTIVE))  return colors.BtnBgActive
    if (sf & S_HOVER)                  return colors.BtnBgHover
    if (sf & S_KB_FOCUS)               return colors.BtnBgFocused
    return defColor
  }

  btnTranspTextColor = function(sf, isEqupped, defColor = colors.TextDefault) {
    if (isEqupped || (sf & S_HOVER))   return colors.TextHighlight
    if (sf & S_ACTIVE)                 return colors.TextActive
    if (sf & S_KB_FOCUS)               return colors.TextDefault
    return defColor
  }

})

console_register_command(function(colorStr, multiplier) {
  if (typeof colorStr != "string" || (colorStr.len() != 8 && colorStr.len() != 6))
    return console_print("first param must be string with len 6 or 8")
  if ((typeof multiplier != "float" && typeof multiplier != "integer") || multiplier < 0)
    return console_print("second param must be numeric > 0")

  let colorInt = hexStringToInt(colorStr)
  let a = min(multiplier * (colorStr.len() == 8 ? ((colorInt & 0xFF000000) >> 24) : 255), 255).tointeger()
  let r = min(multiplier * ((colorInt & 0xFF0000) >> 16), 255).tointeger()
  let g = min(multiplier * ((colorInt & 0xFF00) >> 8), 255).tointeger()
  let b = min(multiplier * (colorInt & 0xFF), 255).tointeger()
  let resColor = (a << 24) + (r << 16) + (g << 8) + b
  console_print(format("color = 0x%X, Color(%d, %d, %d, %d)", resColor, r, g, b, a))
}, "debug.multiply_color")

return colors
