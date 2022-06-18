from "%enlSqGlob/ui_library.nut" import *

local basePortrait = {
  name = ""
  icon = "ui/portraits/default_portrait.svg"
  color = Color(180,180,180)
}

local portraits = {
  berlin_axis_t1_1 = {
    icon = "ui/portraits/berlin/ger_berlin_2.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  berlin_axis_t2_1 = {
    icon = "ui/portraits/berlin/ger_berlin_3.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  berlin_axis_t3_1 = {
    icon = "ui/portraits/berlin/ger_berlin_1.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  berlin_axis_t4_1 = {
    icon = "ui/portraits/berlin/ger_berlin_4.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  berlin_allies_t1_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_4.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  berlin_allies_t2_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_1.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  berlin_allies_t2_2 = {
    icon = "ui/portraits/berlin/ussr_berlin_3.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  berlin_allies_t3_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_2.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  berlin_allies_t3_2 = {
    icon = "ui/portraits/berlin/ussr_berlin_6.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  berlin_allies_t4_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_5.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  moscow_axis_t1_1 = {
    icon = "ui/portraits/moscow/ger_moscow_2.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  moscow_axis_t1_2 = {
    icon = "ui/portraits/moscow/ger_moscow_4.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  moscow_axis_t2_1 = {
    icon = "ui/portraits/moscow/ger_moscow_3.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  moscow_axis_t2_2 = {
    icon = "ui/portraits/moscow/ger_moscow_1.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  moscow_axis_t3_1 = {
    icon = "ui/portraits/moscow/ger_moscow_5.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  moscow_axis_t3_2 = {
    icon = "ui/portraits/moscow/ger_moscow_6.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  moscow_axis_t4_1 = {
    icon = "ui/portraits/moscow/ger_moscow_7.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  moscow_allies_t1_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_5.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  moscow_allies_t2_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_2.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  moscow_allies_t2_2 = {
    icon = "ui/portraits/moscow/ussr_moscow_4.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  moscow_allies_t3_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_3.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  moscow_allies_t3_2 = {
    icon = "ui/portraits/moscow/ussr_moscow_1.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  moscow_allies_t4_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_6.png"
    bgimg = "ui/portraits/back_t4.png"
  }


  normandy_axis_t1_1 = {
    icon = "ui/portraits/normandy/ger_normandy_2.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  normandy_axis_t2_1 = {
    icon = "ui/portraits/normandy/ger_normandy_3.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  normandy_axis_t3_1 = {
    icon = "ui/portraits/normandy/ger_normandy_1.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  normandy_axis_t4_1 = {
    icon = "ui/portraits/normandy/ger_normandy_4.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  normandy_allies_t1_1 = {
    icon = "ui/portraits/normandy/usa_normandy_3.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  normandy_allies_t2_1 = {
    icon = "ui/portraits/normandy/usa_normandy_1.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  normandy_allies_t3_1 = {
    icon = "ui/portraits/normandy/usa_normandy_2.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  normandy_allies_t4_1 = {
    icon = "ui/portraits/normandy/usa_normandy_4.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  tunisia_axis_t1_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_4.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  tunisia_axis_t2_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_3.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  tunisia_axis_t3_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_1.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  tunisia_axis_t4_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_5.png"
    bgimg = "ui/portraits/back_t4.png"
  }

  tunisia_allies_t1_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_2.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  tunisia_allies_t2_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_1.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  tunisia_allies_t2_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_4.png"
    bgimg = "ui/portraits/back_t2.png"
  }
  tunisia_allies_t3_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_3.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  tunisia_allies_t3_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_5.png"
    bgimg = "ui/portraits/back_t3.png"
  }
  tunisia_allies_t4_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_6.png"
    bgimg = "ui/portraits/back_t4.png"
  }
}

local nickFrames = {
  pistol = @(n) $"⌈{n}⌉"
  flame = @(n) $"⋔{n}⋕"
  flag = @(n) $"⋝{n}⋞"
  rhomb = @(n) $"⋍{n}⋎"
  pyramid = @(n) $"⋒{n}⋓"
  grenade = @(n) $"⋘{n}⋙"
  helmet = @(n) $"⋤{n}⋥"
  rocket = @(n) $"⋰{n}⋱"
  line_1 = @(n) $"⋚{n}⋚"
  line_2 = @(n) $"⋦{n}⋦"
  lines_1 = @(n) $"⋛{n}⋛"
  lines_2 = @(n) $"⋜{n}⋜"
  lines_3 = @(n) $"⌂{n}⌆"
  lines_4 = @(n) $"⋩{n}⋩"
  wings_1 = @(n) $"⋖{n}⋗"
  wings_2 = @(n) $"⋢{n}⋣"
  wings_3 = @(n) $"⋪{n}⋫"
  wings_4 = @(n) $"⋬{n}⋭"
  wings_5 = @(n) $"⋮{n}⋯"
  wings_6 = @(n) $"⋧{n}⋨"
  nickFrame_1 = @(n) $"⋏{n}⋏"
  nickFrame_2 = @(n) $"⋐{n}⋐"
  nickFrame_3 = @(n) $"⋑{n}⋑"
  nickFrame_4 = @(n) $"⋟{n}⋟"
  nickFrame_5 = @(n) $"⋠{n}⋠"
  nickFrame_6 = @(n) $"⋡{n}⋡"
  nickFrame_100_days_in_row = @(n) $"⌠{n}⌠"
  nickFrame_365_days_in_row = @(n) $"⌋{n}⌊"
  nickFrame_730_days_in_row = @(n) $"⌡{n}⌢"
}

local decoratorsPresentation = {
  portrait = portraits
  nickFrame = nickFrames.map(@(framedNickName) { framedNickName }) //is we really need this?
}

return {
  basePortrait
  portraits
  nickFrames
  decoratorsPresentation

  getPortrait = @(id) portraits?[id] ?? basePortrait
  frameNick = @(nick, frameId) nickFrames?[frameId](nick) ?? nick
}
