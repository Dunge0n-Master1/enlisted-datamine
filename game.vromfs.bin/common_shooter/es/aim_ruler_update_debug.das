options no_aot
require ecs
require app
require EnlistedWeapon
require common_shooter.es.human_weap_common

[es(tag=render, before=draw_ruler_es, REQUIRE=aimRulerDebug)]
def aim_ruler_update_es(evt : UpdateStageInfoRenderDebug; var shouldDraw : bool&; var tracePos : float3&; var traceDir : float3&)
  shouldDraw = false
  find_query() <| $ [es(REQUIRE=hero)] (eid : EntityId)
    var aimTm : float3x4
    shouldDraw = human_weap_get_aim_tm(eid, get_sync_time(), aimTm)
    if !shouldDraw
      return true
    traceDir = aimTm[0]
    tracePos = aimTm[3]
    return true