from "%enlSqGlob/ui_library.nut" import *


const MEDAL_SIZE = 180

let mkSizeByParent = @(size) [
  pw(100.0 * size[0] / MEDAL_SIZE),
  ph(100.0 * size[1] / MEDAL_SIZE)
]

let mkImageParams = @(pxSize, pxOffset = [0,0]) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = mkSizeByParent(pxSize)
  pos = mkSizeByParent(pxOffset)
}

let mkStackImage = @(img, pxSize, pxOffset = [0, 0]) {
  img = $"ui/skin#/medals/{img}"
  params = mkImageParams(pxSize, pxOffset)
}

let medalsPresentation = {
  medal_moscow_top_1_solo = {
    name = "medals/medal_moscow_top_1_solo"
    bgImage = "ui/skin#/medals/bg_moscow_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 60])
    ]
    weight = 10
  }
  medal_moscow_top_2_solo = {
    name = "medals/medal_moscow_top_2_solo"
    bgImage = "ui/skin#/medals/bg_moscow_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 60])
    ]
    weight = 9
  }
  medal_moscow_top_3_solo = {
    name = "medals/medal_moscow_top_3_solo"
    bgImage = "ui/skin#/medals/bg_moscow_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 60])
    ]
    weight = 8
  }
  medal_moscow_top_10_solo = {
    name = "medals/medal_moscow_top_10_solo"
    bgImage = "ui/skin#/medals/bg_moscow_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 60])
    ]
    weight = 7
  }
  medal_moscow_top_10p_solo = {
    name = "medals/medal_moscow_top_10p_solo"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 60])
    ]
    weight = 6
  }
  medal_moscow_top_25p_solo = {
    name = "medals/medal_moscow_top_25p_solo"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 60])
    ]
      weight = 5
  }
  medal_moscow_top_50p_solo = {
    name = "medals/medal_moscow_top_50p_solo"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 60])
    ]
    weight = 4
  }
  medal_moscow_events_solo = {
    name = "medals/medal_moscow_events_solo"
    bgImage = "ui/skin#/medals/bg_moscow_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 60])
    ]
    weight = 3
  }
  medal_moscow_top_1_squad = {
    name = "medals/medal_moscow_top_1_squad"
    bgImage = "ui/skin#/medals/bg_moscow_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 60])
    ]
    weight = 10
  }
  medal_moscow_top_2_squad = {
    name = "medals/medal_moscow_top_2_squad"
    bgImage = "ui/skin#/medals/bg_moscow_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 60])
    ]
    weight = 9
  }
  medal_moscow_top_3_squad = {
    name = "medals/medal_moscow_top_3_squad"
    bgImage = "ui/skin#/medals/bg_moscow_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 60])
    ]
    weight = 8
  }
  medal_moscow_top_10_squad = {
    name = "medals/medal_moscow_top_10_squad"
    bgImage = "ui/skin#/medals/bg_moscow_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 60])
    ]
    weight = 7
  }
  medal_moscow_top_10p_squad = {
    name = "medals/medal_moscow_top_10p_squad"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 60])
    ]
    weight = 6
  }
  medal_moscow_top_25p_squad = {
    name = "medals/medal_moscow_top_25p_squad"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 60])
    ]
    weight = 5
  }
  medal_moscow_top_50p_squad = {
    name = "medals/medal_moscow_top_50p_squad"
    bgImage = "ui/skin#/medals/bg_moscow_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 60])
    ]
    weight = 4
  }
  medal_moscow_events_squad = {
    name = "medals/medal_moscow_events_squad"
    bgImage = "ui/skin#/medals/bg_moscow_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 60])
    ]
    weight = 3
  }

  medal_normandy_top_1_solo = {
    name = "medals/medal_normandy_top_1_solo"
    bgImage = "ui/skin#/medals/bg_normandy_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 40])
    ]
    weight = 10
  }
  medal_normandy_top_2_solo = {
    name = "medals/medal_normandy_top_2_solo"
    bgImage = "ui/skin#/medals/bg_normandy_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 40])
    ]
    weight = 9
  }
  medal_normandy_top_3_solo = {
    name = "medals/medal_normandy_top_3_solo"
    bgImage = "ui/skin#/medals/bg_normandy_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 40])
    ]
    weight = 8
  }
  medal_normandy_top_10_solo = {
    name = "medals/medal_normandy_top_10_solo"
    bgImage = "ui/skin#/medals/bg_normandy_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 40])
    ]
    weight = 7
  }
  medal_normandy_top_10p_solo = {
    name = "medals/medal_normandy_top_10p_solo"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 40])
    ]
    weight = 6
  }
  medal_normandy_top_25p_solo = {
    name = "medals/medal_normandy_top_25p_solo"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 40])
    ]
      weight = 5
  }
  medal_normandy_top_50p_solo = {
    name = "medals/medal_normandy_top_50p_solo"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 40])
    ]
    weight = 4
  }
  medal_normandy_events_solo = {
    name = "medals/medal_normandy_events_solo"
    bgImage = "ui/skin#/medals/bg_normandy_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 40])
    ]
    weight = 3
  }
  medal_normandy_top_1_squad = {
    name = "medals/medal_normandy_top_1_squad"
    bgImage = "ui/skin#/medals/bg_normandy_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 40])
    ]
    weight = 10
  }
  medal_normandy_top_2_squad = {
    name = "medals/medal_normandy_top_2_squad"
    bgImage = "ui/skin#/medals/bg_normandy_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 40])
    ]
    weight = 9
  }
  medal_normandy_top_3_squad = {
    name = "medals/medal_normandy_top_3_squad"
    bgImage = "ui/skin#/medals/bg_normandy_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 40])
    ]
    weight = 8
  }
  medal_normandy_top_10_squad = {
    name = "medals/medal_normandy_top_10_squad"
    bgImage = "ui/skin#/medals/bg_normandy_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 40])
    ]
    weight = 7
  }
  medal_normandy_top_10p_squad = {
    name = "medals/medal_normandy_top_10p_squad"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 40])
    ]
    weight = 6
  }
  medal_normandy_top_25p_squad = {
    name = "medals/medal_normandy_top_25p_squad"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 40])
    ]
    weight = 5
  }
  medal_normandy_top_50p_squad = {
    name = "medals/medal_normandy_top_50p_squad"
    bgImage = "ui/skin#/medals/bg_normandy_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 40])
    ]
    weight = 4
  }
  medal_normandy_events_squad = {
    name = "medals/medal_normandy_events_squad"
    bgImage = "ui/skin#/medals/bg_normandy_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 40])
    ]
    weight = 3
  }

  medal_berlin_top_1_solo = {
    name = "medals/medal_berlin_top_1_solo"
    bgImage = "ui/skin#/medals/bg_berlin_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 32])
    ]
    weight = 10
  }
  medal_berlin_top_2_solo = {
    name = "medals/medal_berlin_top_2_solo"
    bgImage = "ui/skin#/medals/bg_berlin_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 32])
    ]
    weight = 9
  }
  medal_berlin_top_3_solo = {
    name = "medals/medal_berlin_top_3_solo"
    bgImage = "ui/skin#/medals/bg_berlin_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 32])
    ]
    weight = 8
  }
  medal_berlin_top_10_solo = {
    name = "medals/medal_berlin_top_10_solo"
    bgImage = "ui/skin#/medals/bg_berlin_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 32])
    ]
    weight = 7
  }
  medal_berlin_top_10p_solo = {
    name = "medals/medal_berlin_top_10p_solo"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 32])
    ]
    weight = 6
  }
  medal_berlin_top_25p_solo = {
    name = "medals/medal_berlin_top_25p_solo"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 32])
    ]
      weight = 5
  }
  medal_berlin_top_50p_solo = {
    name = "medals/medal_berlin_top_50p_solo"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 32])
    ]
    weight = 4
  }
  medal_berlin_events_solo = {
    name = "medals/medal_berlin_events_solo"
    bgImage = "ui/skin#/medals/bg_berlin_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 32])
    ]
    weight = 3
  }
  medal_berlin_top_1_squad = {
    name = "medals/medal_berlin_top_1_squad"
    bgImage = "ui/skin#/medals/bg_berlin_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 32])
    ]
    weight = 10
  }
  medal_berlin_top_2_squad = {
    name = "medals/medal_berlin_top_2_squad"
    bgImage = "ui/skin#/medals/bg_berlin_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 32])
    ]
    weight = 9
  }
  medal_berlin_top_3_squad = {
    name = "medals/medal_berlin_top_3_squad"
    bgImage = "ui/skin#/medals/bg_berlin_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 32])
    ]
    weight = 8
  }
  medal_berlin_top_10_squad = {
    name = "medals/medal_berlin_top_10_squad"
    bgImage = "ui/skin#/medals/bg_berlin_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 32])
    ]
    weight = 7
  }
  medal_berlin_top_10p_squad = {
    name = "medals/medal_berlin_top_10p_squad"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 32])
    ]
    weight = 6
  }
  medal_berlin_top_25p_squad = {
    name = "medals/medal_berlin_top_25p_squad"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 32])
    ]
    weight = 5
  }
  medal_berlin_top_50p_squad = {
    name = "medals/medal_berlin_top_50p_squad"
    bgImage = "ui/skin#/medals/bg_berlin_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 32])
    ]
    weight = 4
  }
  medal_berlin_events_squad = {
    name = "medals/medal_berlin_events_squad"
    bgImage = "ui/skin#/medals/bg_berlin_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 32])
    ]
    weight = 3
  }

  medal_tunisia_top_1_solo = {
    name = "medals/medal_tunisia_top_1_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 10
  }
  medal_tunisia_top_2_solo = {
    name = "medals/medal_tunisia_top_2_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 9
  }
  medal_tunisia_top_3_solo = {
    name = "medals/medal_tunisia_top_3_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 8
  }
  medal_tunisia_top_10_solo = {
    name = "medals/medal_tunisia_top_10_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 7
  }
  medal_tunisia_top_10p_solo = {
    name = "medals/medal_tunisia_top_10p_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 6
  }
  medal_tunisia_top_25p_solo = {
    name = "medals/medal_tunisia_top_25p_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
      weight = 5
  }
  medal_tunisia_top_50p_solo = {
    name = "medals/medal_tunisia_top_50p_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 4
  }
  medal_tunisia_events_solo = {
    name = "medals/medal_tunisia_events_solo"
    bgImage = "ui/skin#/medals/bg_tunisia_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 3
  }
  medal_tunisia_top_1_squad = {
    name = "medals/medal_tunisia_top_1_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 10
  }
  medal_tunisia_top_2_squad = {
    name = "medals/medal_tunisia_top_2_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 9
  }
  medal_tunisia_top_3_squad = {
    name = "medals/medal_tunisia_top_3_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 8
  }
  medal_tunisia_top_10_squad = {
    name = "medals/medal_tunisia_top_10_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 7
  }
  medal_tunisia_top_10p_squad = {
    name = "medals/medal_tunisia_top_10p_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 6
  }
  medal_tunisia_top_25p_squad = {
    name = "medals/medal_tunisia_top_25p_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 5
  }
  medal_tunisia_top_50p_squad = {
    name = "medals/medal_tunisia_top_50p_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 4
  }
  medal_tunisia_events_squad = {
    name = "medals/medal_tunisia_events_squad"
    bgImage = "ui/skin#/medals/bg_tunisia_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 3
  }

  medal_stalingrad_top_1_solo = {
    name = "medals/medal_stalingrad_top_1_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 10
  }
  medal_stalingrad_top_2_solo = {
    name = "medals/medal_stalingrad_top_2_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 9
  }
  medal_stalingrad_top_3_solo = {
    name = "medals/medal_stalingrad_top_3_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_solo.avif", [36, 28], [0, 34])
    ]
    weight = 8
  }
  medal_stalingrad_top_10_solo = {
    name = "medals/medal_stalingrad_top_10_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 7
  }
  medal_stalingrad_top_10p_solo = {
    name = "medals/medal_stalingrad_top_10p_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 6
  }
  medal_stalingrad_top_25p_solo = {
    name = "medals/medal_stalingrad_top_25p_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
      weight = 5
  }
  medal_stalingrad_top_50p_solo = {
    name = "medals/medal_stalingrad_top_50p_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 4
  }
  medal_stalingrad_events_solo = {
    name = "medals/medal_stalingrad_events_solo"
    bgImage = "ui/skin#/medals/bg_stalingrad_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_solo_wh.avif", [36, 28], [0, 34])
    ]
    weight = 3
  }
  medal_stalingrad_top_1_squad = {
    name = "medals/medal_stalingrad_top_1_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_01.avif"
    stackImages = [
      mkStackImage("top_10_01.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 10
  }
  medal_stalingrad_top_2_squad = {
    name = "medals/medal_stalingrad_top_2_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_02.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 9
  }
  medal_stalingrad_top_3_squad = {
    name = "medals/medal_stalingrad_top_3_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_02.avif"
    stackImages = [
      mkStackImage("top_10_03.avif", [50, 60], [0, -8])
      mkStackImage("mode_squad.avif", [36, 28], [0, 34])
    ]
    weight = 8
  }
  medal_stalingrad_top_10_squad = {
    name = "medals/medal_stalingrad_top_10_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_gold_03.avif"
    stackImages = [
      mkStackImage("top_10_10.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 7
  }
  medal_stalingrad_top_10p_squad = {
    name = "medals/medal_stalingrad_top_10p_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_10p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 6
  }
  medal_stalingrad_top_25p_squad = {
    name = "medals/medal_stalingrad_top_25p_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_25p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 5
  }
  medal_stalingrad_top_50p_squad = {
    name = "medals/medal_stalingrad_top_50p_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_silver.avif"
    stackImages = [
      mkStackImage("top_50p.avif", [80, 48], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 4
  }
  medal_stalingrad_events_squad = {
    name = "medals/medal_stalingrad_events_squad"
    bgImage = "ui/skin#/medals/bg_stalingrad_bronze.avif"
    stackImages = [
      mkStackImage("event_icon_2.avif", [64, 54], [0, -8])
      mkStackImage("mode_squad_wh.avif", [36, 28], [0, 34])
    ]
    weight = 3
  }
}

return {
  medalsPresentation
  MEDAL_SIZE
}
