from "%enlSqGlob/ui_library.nut" import *

let style = {
  TEAM0_COLOR_FG = Color(70,90,250)
  TEAM0_COLOR_FG_LT = Color(70,90,250,120)
  TEAM0_COLOR_FG_TR = Color(35,45,125,120)
  TEAM0_COLOR_BG = Color(50,60,100,110)

  TEAM1_COLOR_FG = Color(250,70,70)
  TEAM1_COLOR_FG_TR = Color(125,35,35,120)
  TEAM1_COLOR_FG_LT = Color(250,70,70,120)
  TEAM1_COLOR_BG = Color(100,50,40,110)

  DEFAULT_TEXT_COLOR = Color(180, 180, 180, 120)
  BRIGHT_TEXT_COLOR = Color(220, 220, 220)
  HIGHLIGHT_COLOR = Color(200, 248, 255)

  WINDOW_COLOR = Color(56, 56, 56, 220)
  CONTROL_BG_COLOR = Color(28, 28, 28, 220)
  OVERLAY_PANEL_COLOR = Color(20, 28, 35, 160)

  TEAM0_TEXT_COLOR = Color(150,160,255,120)
  TEAM1_TEXT_COLOR = Color(255,160,160,120)
  MY_SQUAD_TEXT_COLOR = Color(150,255,160,120)
  MESSAGE_BG_START = Color(30,30,30,10)
  MESSAGE_BG_END   = Color(50,50,50,100)
  SUCCESS_TEXT_COLOR = Color(150,255,160,120)
  FAIL_TEXT_COLOR = Color(255,160,160,120)
  DEAD_TEXT_COLOR = Color(80,30,30,120)

  SELECTION_BORDER_COLOR = Color(235,155,50,120)

  HUD_TIPS_BG = Color(0, 0, 0, 50)
  HUD_TIPS_BG_BLUR = Color(200, 200, 200, 205)
  HUD_TIPS_HOTKEY_FG = Color(120,120,50,20)
  HUD_TIPS_FG = Color(128,128,128,60)
  HUD_TIPS_HILIGHT = Color(200,200,200,110)

  HUD_TIPS_FAIL_TEXT_COLOR = Color(255,160,160,200)

  squadButtonFillColor = function(sf, isAlive, isCurrent) {
    if (!isAlive)
      return Color(40,10,10,180)
    if (isCurrent)
      return (sf & S_HOVER) ? Color(60,60,60,180): Color(30,30,30,180)
    return (sf & S_HOVER) ? Color(30,30,30,180): Color(0,0,0,180)
  }

  squadButtonBorderColor = function(sf, isAlive, isCurrent) {
    if (isCurrent)
      return (sf & S_ACTIVE) ? Color(255,255,255,180) : Color(160,160,160,50)
    if (!isAlive)
      return Color(0,0,0,0)
    return (sf & S_ACTIVE) ? Color(255,255,255,200) : Color(0,0,0,0)
  }

  blurBack = {
    rendObj = ROBJ_WORLD_BLUR
    size = flex()
    color = Color(200,200,200,215)
  }
}

return style
