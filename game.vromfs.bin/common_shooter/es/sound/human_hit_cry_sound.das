require ecs
require common_shooter.events_common_shooter
require human_sounds.modules.human_sounds_events


[es(tag=sound, REQUIRE=humanHitCrySound)]
def human_hit_cry_sound(evt : EventOnEntityHit; eid : EntityId)
  if eid == evt.victim
    sendEvent(eid, [[CmdHumanVoiceEffect phrase="hitCry"]])
