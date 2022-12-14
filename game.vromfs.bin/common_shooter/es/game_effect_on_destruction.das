require ecs
require app
require strings
require game.es.events
require game.es.game_effect_common
require danetlibs.native_dasevents.main.native_events


def is_target_active(eid : EntityId; game_effect__affectsInvisible : bool)
  var active = true
  if !game_effect__affectsInvisible
    query(eid) <| $ [es] (game_effect__invisible = false)
      active = !game_effect__invisible
  return active

[es(tag=server, REQUIRE=game_effect__applyOnDestruction)]
def game_effect_on_destruction_perk(evt : EventRiExtraDestroyed;
                                    game_effect__perkName : string;
                                    game_effect__perkEntityTemplate : string;
                                    game_effect__perkTime : float;
                                    game_effect__affectsInvisible = false)
  let offender = get_hero_offender(evt.offenderEid)
  if is_target_active(offender, game_effect__affectsInvisible)
    let curTime = get_sync_time()
    createEntity(game_effect__perkEntityTemplate) <| $(var init : ComponentsInitializer)
      set(init, "game_effect__perk__target", offender)
      set(init, "game_effect__perk__startAtTime", curTime)
      set(init, "game_effect__perk__endAtTime", curTime + game_effect__perkTime)
      set(init, "game_effect__perkName", game_effect__perkName)


[es(tag=server)]
def trap_triggered_by_destruction_message(evt : EventRiExtraDestroyed; game_effect__localNotification : string; game_effect__affectsInvisible = false)
  let offender = get_hero_offender(evt.offenderEid)
  if !empty(game_effect__localNotification) && is_target_active(offender, game_effect__affectsInvisible)
    sendEvent(offender, [[CmdHeroLogEvent event="spray_log", text=game_effect__localNotification]])

[es(tag=server)]
def trap_triggered_by_destruction_owner_message(evt : EventRiExtraDestroyed; ownerEid : EntityId; game_effect__ownerNotification : string; game_effect__affectsInvisible = false)
  let offender = get_hero_offender(evt.offenderEid)
  if !empty(game_effect__ownerNotification) && ownerEid != offender && is_target_active(offender, game_effect__affectsInvisible)
    sendEvent(ownerEid, [[CmdHeroLogEvent event="spray_log", text=game_effect__ownerNotification]])
