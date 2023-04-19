require ecs
require app
require common_shooter.events_common_shooter
require human_sounds.modules.human_sounds_events


[es(tag=sound)]
def human_hit_cry_sound(evt : EventOnEntityHit;
                        eid : EntityId;
                        human_hit_cry_sound__cooldown : float;
                        var human_hit_cry_sound__nextTime : float&)
  if eid == evt.victim && get_sync_time() >= human_hit_cry_sound__nextTime
    human_hit_cry_sound__nextTime = get_sync_time() + human_hit_cry_sound__cooldown
    sendEvent(eid, [[CmdHumanVoiceEffect phrase="hitCry"]])
