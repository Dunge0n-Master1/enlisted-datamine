require ecs
require ecs.safe
require game.utils.team
require human_sounds_net.modules.human_sounds_net_events
require game.events_game
require strings

def for_each_in_zone(zone_eid : EntityId; callback : block<(eid : EntityId; team : int) : void>)
  query(zone_eid) <| $ [es] (teamPresence : Object)
    for it in teamPresence
      let team = to_int(it.key)
      let presence = it.value as Array
      if presence == null
        return
      for eidObj in *presence
        let eid = eidObj ?? INVALID_ENTITY_ID
        callback |> invoke(eid, team)

[es(tag=server)]
def zone_capture_human_net_speech_es(evt : EventZoneStartCapture)
  for_each_in_zone(evt.eid) <| $(eid : EntityId; team : int)
    if is_teams_friendly(team, evt.team)
      sendEvent(eid, [[CmdRequestHumanSpeech phrase="startCapture"]])

[es(tag=server)]
def zone_decapture_human_net_speech_es(evt : EventZoneStartDecapture)
  for_each_in_zone(evt.eid) <| $(eid : EntityId; team : int)
    if !is_teams_friendly(team, evt.team)
      sendEvent(eid, [[CmdRequestHumanSpeech phrase="enemyStartCapture"]])
