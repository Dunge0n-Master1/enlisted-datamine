require ecs
require app
require math.base
require game.es.events
require game.utils.hero
require game.events_game
require enlisted.events_enlisted
require common_shooter.events_common_shooter


[es(tag=gameClient, no_order, REQUIRE=mortar_marker)]
def mortar_kill_marker_cleanup_es(info : ParallelUpdateFrameDelayed; eid : EntityId; marker__endTime : float)
  if info.curTime > marker__endTime
    destroyEntity(eid)

def create_minimap_icon(minimap_icon : string; pos : float3; showTime : float)
  createEntity(minimap_icon) <| $(var init : ComponentsInitializer)
    var tm = IDENT_TM
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "marker__endTime", get_sync_time() + showTime)

[es(tag=gameClient)]
def mortar_kill_mark_create_es(evt : EventEntityDied; transform : float3x4)
  if evt.offender == INVALID_ENTITY_ID || !has(evt.offender, "hero")
    return
  ecs::find_query() <| $ [es(REQUIRE=mortar)] (gun__owner : ecs::EntityId;
                                               gun__propsId : int;
                                               mortar__killIconShowTime : float;
                                               mortar__killIconName : string)
    if gun__owner == evt.offender && evt.gunPropsId == gun__propsId
      create_minimap_icon(mortar__killIconName, transform[3], mortar__killIconShowTime)
      return true
    return false


[es(tag=gameClient, REQUIRE=msg_sink)]
def mortar_shell_explode_mark_create_es(evt : EventOnShellExploded)
  if evt.owner == INVALID_ENTITY_ID || !has(evt.owner, "hero")
    return
  ecs::find_query() <| $ [es(REQUIRE=mortar)] (gun__owner : ecs::EntityId;
                                               gun__propsId : int;
                                               mortar__explodeIconShowTime : float;
                                               mortar__explodeIconName : string)
    if gun__owner == evt.owner && evt.gunPropsId == gun__propsId
      create_minimap_icon(mortar__explodeIconName, evt.explPos, mortar__explodeIconShowTime)
      return true
    return false