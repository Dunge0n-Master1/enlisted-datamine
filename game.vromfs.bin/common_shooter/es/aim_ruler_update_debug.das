options no_aot
require ecs

[es(tag=render, before=draw_ruler_es, REQUIRE=aimRulerDebug)]
def aim_ruler_update_es(evt : UpdateStageInfoRenderDebug; var shouldDraw : bool&; var tracePos : float3&; var traceDir : float3&)
  shouldDraw = find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false
    traceDir = transform[2]
    tracePos = transform[3]
    return true