options no_aot
require ecs
require ecs.ecs_template
require app
require game.utils.team
require danetlibs.renderer.includes.render_events
require game.utils.hero
require common_shooter.es.human_weap_common
require DagorSystem
require DagorMath
require DagorConsole
require DagorDebug3D
require EnlistedWeapon
require EnlistedUI


[console_cmd(name="hud.force_crosshair")]
def force_crosshair_debug_cmd(state : int = -1)
  find_query() <| $ [es] (var ui_crosshair_state__debugForceCrosshair : bool&)
    if state < 0
      ui_crosshair_state__debugForceCrosshair = !ui_crosshair_state__debugForceCrosshair
    elif state == 0
      ui_crosshair_state__debugForceCrosshair = false
    else
      ui_crosshair_state__debugForceCrosshair = true

    let found = find_query() <| $ [es(REQUIRE=crosshairDebug)] (eid : EntityId)
      if !ui_crosshair_state__debugForceCrosshair
        destroyEntity(eid)
      return false

    if ui_crosshair_state__debugForceCrosshair && !found
      createEntity("crosshair_debug_draw")

    return false

[es(tag=dev, after=ui_crosshair_state_es, REQUIRE=crosshairDebug)]
def ui_crosshair_debug_draw_es(info : RenderEventUI)
  let hero = get_controlled_hero()

  var gunTraceLen = 0.0
  query(hero) <| $ [es] (human_weap__tracerayLen : float = 0.0)
    gunTraceLen = human_weap__tracerayLen

  var uiViewItm : float3x4
  get_ui_view_itm(uiViewItm)
  var uiViewTm : float3x4
  get_ui_view_tm(uiViewTm)

  var shootTm : float3x4
  var tracePos : float3
  var traceDir : float3

  let curTime = get_sync_time()

  if human_weap_get_aim_tm(hero, curTime, shootTm)
    traceDir = shootTm[0]
    tracePos = shootTm[3]
  else
    tracePos = uiViewItm[3]
    traceDir = uiViewItm[2]

  let traceEndPos = tracePos + traceDir * gunTraceLen
  draw_debug_line_buffered(tracePos, traceEndPos, E3DCOLOR(0xFFFF1010), 10)