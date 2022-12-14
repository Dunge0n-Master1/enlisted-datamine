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
  normandy_axis_event_marathon_summer_2022 = {
    icon = "ui/portraits/normandy/ger_normandy_5.png"
  }
  normandy_axis_lb_event_summer_2022_t1 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_1.png"
  }
  normandy_axis_lb_event_summer_2022_t2 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_2.png"
  }
  normandy_axis_lb_event_summer_2022_t3 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_3.png"
  }
  normandy_axis_lb_event_summer_2022_t4 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_4.png"
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
  tunisia_allies_t1_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_1.png"
    bgimg = "ui/portraits/back_t1.png"
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
  tunisia_allies_event_marathon_summer_2022 = {
    icon = "ui/portraits/tunisia/allies_tunisia_7.png"
  }



//EVENT AND PREORDER PORTRAITS
  preorder_dec_2022 = {
    icon = "ui/portraits/moscow/preorder_dec_2022.png"
  }
  pacific_allies_preorder_2022 = {
    icon = "ui/portraits/pacific/pacific_allies_preorder_2022.png"
  }
  enlisted2years_portrait_ussr = {
    icon = "ui/portraits/event/enlisted2years_portrait_ussr.png"
  }
  enlisted2years_portrait_britain = {
    icon = "ui/portraits/event/enlisted2years_portrait_britain.png"
  }
  enlisted2years_portrait_usa = {
    icon = "ui/portraits/event/enlisted2years_portrait_usa.png"
  }
  armory_event_portrait_usa = {
    icon = "ui/portraits/normandy/armory_event_portrait_usa.png"
  }
  armory_event_portrait_ger = {
    icon = "ui/portraits/tunisia/armory_event_portrait_ger.png"
  }
  xmas_event_ussr_portrait = {
    icon = "ui/portraits/event/xmas_event_ussr_portrait.png"
  }
  xmas_event_ger_portrait = {
    icon = "ui/portraits/event/xmas_event_ger_portrait.png"
  }



  common_china_portrait_1 = {
    icon = "ui/portraits/common/china_portrait_1.png"
    bgimg = "ui/portraits/back_t1.png"
  }
  common_china_portrait_2 = {
    icon = "ui/portraits/common/china_portrait_2.png"
  }
  common_china_portrait_3 = {
    icon = "ui/portraits/common/china_portrait_3.png"
  }
  common_china_portrait_4 = {
    icon = "ui/portraits/common/china_portrait_4.png"
  }
  common_china_portrait_5 = {
    icon = "ui/portraits/common/china_portrait_5.png"
  }
  common_china_portrait_6 = {
    icon = "ui/portraits/common/china_portrait_6.png"
  }
  common_china_portrait_7 = {
    icon = "ui/portraits/common/china_portrait_7.png"
  }
  common_china_portrait_8 = {
    icon = "ui/portraits/common/china_portrait_8.png"
  }
  common_china_portrait_9 = {
    icon = "ui/portraits/common/china_portrait_9.png"
  }
  common_china_portrait_10 = {
    icon = "ui/portraits/common/china_portrait_10.png"
  }
  common_china_portrait_11 = {
    icon = "ui/portraits/common/china_portrait_11.png"
  }
  common_china_portrait_12 = {
    icon = "ui/portraits/common/china_portrait_12.png"
  }
  common_top_rank_portrait_1 = {
    icon = "ui/portraits/common/top_rank_portrait_1.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_2 = {
    icon = "ui/portraits/common/top_rank_portrait_2.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_3 = {
    icon = "ui/portraits/common/top_rank_portrait_3.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_4 = {
    icon = "ui/portraits/common/top_rank_portrait_4.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_5 = {
    icon = "ui/portraits/common/top_rank_portrait_5.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_6 = {
    icon = "ui/portraits/common/top_rank_portrait_6.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_7 = {
    icon = "ui/portraits/common/top_rank_portrait_7.png"
    bgimg = "ui/portraits/back_t4.png"
  }
  common_top_rank_portrait_8 = {
    icon = "ui/portraits/common/top_rank_portrait_8.png"
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
  kongzhong_star = @(n) $"␉{n}␉"
  kongzhong_nickFrame_1 = @(n) $"␛{n}␛"
  kongzhong_nickFrame_2 = @(n) $"␜{n}␜"
  kongzhong_nickFrame_3 = @(n) $"␝{n}␝"
  kongzhong_nickFrame_4 = @(n) $"␞{n}␞"
  kongzhong_nickFrame_5 = @(n) $"␟{n}␠"
  kongzhong_nickFrame_6 = @(n) $"┅{n}┅"
  kongzhong_nickFrame_7 = @(n) $"┆{n}┆"
  kongzhong_nickFrame_8 = @(n) $"┇{n}┈"
  kongzhong_nickFrame_9 = @(n) $"┉{n}┊"
  kongzhong_nickFrame_10 = @(n) $"┋{n}┋"
  kongzhong_nickFrame_11 = @(n) $"┌{n}┌"
  kongzhong_nickFrame_12 = @(n) $"┍{n}┍"
  pacific_nickFrame_1 = @(n) $"␡{n}␡"
  pacific_nickFrame_2 = @(n) $"␣{n}␢"
  pacific_nickFrame_3 = @(n) $"␤{n}─"
  pacific_nickFrame_4 = @(n) $"━{n}│"
  pacific_nickFrame_5 = @(n) $"┃{n}┃"
  pacific_nickFrame_6 = @(n) $"␅{n}␆"
  nickFrame_hammer = @(n) $"⌣{n}␀"
  nickFrame_wrench = @(n) $"␁{n}␁"
  nickFrame_gear = @(n) $"␂{n}␂"
  nickFrame_bomb_1 = @(n) $"␃{n}␃"
  nickFrame_bomb_2 = @(n) $"␌{n}␌"
  nickFrame_tnt = @(n) $"␄{n}␄"
  nickFrame_rocket = @(n) $"␇{n}␈"
  nickFrame_bullet = @(n) $"␊{n}␊"
  nickFrame_target = @(n) $"␋{n}␋"
  nickFrame_aim = @(n) $"␎{n}␎"
  nickFrame_ribbon_1 = @(n) $"␏{n}␐"
  nickFrame_parachute = @(n) $"␑{n}␑"
  nickFrame_lines_5 = @(n) $"␒{n}␒"
  nickFrame_lines_6 = @(n) $"␓{n}␔"
  nickFrame_lines_7 = @(n) $"␕{n}␖"
  nickFrame_lines_8 = @(n) $"␗{n}␘"
  nickFrame_lines_9 = @(n) $"␙{n}␚"
  nickFrame_samurai = @(n) $"┄{n}┄"
  nickFrame_mgun = @(n) $"┏{n}┏"
  nickFrame_preorder_mgun = @(n) $"┏{n}┏"
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
