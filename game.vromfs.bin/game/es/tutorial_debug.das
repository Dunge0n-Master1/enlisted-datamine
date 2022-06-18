options no_aot
require ecs
require math.base
require DagorMath
require math.color
require CollRes
require DagorDebug3D
require DagorConsole
require enlisted.tutorial.tutorial_common

[console_cmd(name="tutorial_zone.debug")]
def tutorial_zone_debug()
  var found = false
  query() <| $ [es(REQUIRE=tutorialZoneDebug)] (eid : EntityId)
    destroyEntity(eid)
    found = true

  if !found
    createEntity("tutorial_zone_debug")
  console_print("{found ? "deactivate" : "activate"} tutorial zone debug")


def draw_debug_tutorial_zone(eid; transform)
  var seed = int(uint(eid) + 255u)
  let color = rnd_color(seed)
  set_cached_debug_lines_wtm(transform)
  draw_cached_debug_box(TUTORIAL_IDENTITY_BOX, color)
  set_cached_debug_lines_wtm(IDENT_TM)

[es(tag=dev, tag=render, no_order, REQUIRE=tutorialZoneDebug)]
def tutorial_zone_debug_draw_es(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es(REQUIRE=tutorialZone)] (eid : EntityId; transform : float3x4; tutorial_zone__active : bool)
    if tutorial_zone__active || has(eid, "daeditor__selected")
      draw_debug_tutorial_zone(eid, transform)

[console_cmd(name="tutorial.debug_stage")]
def tutorial_debug_stage_cmd()
  let eid = getSingletonEntity("tutorial_stage_debug")
  if !!eid
    destroyEntity(eid)
  else
    createEntity("tutorial_stage_debug")

  console_print("{!!eid ? "deactivate" : "activate"} tutorial zone debug")

[es(tag=dev, on_appear, REQUIRE=tutor_stage__next)]
def tutorial_stage_visual_debug_es(evt : Event; eid : EntityId)
  if getSingletonEntity("tutorial_stage_debug") != INVALID_ENTITY_ID
    visual_log("{eid} => {getEntityTemplateName(eid)}")
