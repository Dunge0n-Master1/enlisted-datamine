require ecs
require app
require EnlistedDm
require common_shooter.events_common_shooter
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, before=human_hit_cry_sound)]
def human_voice_effect_coughing_on_hit(evt : EventOnEntityHit; eid : EntityId;
                                       human_voice_effect__coughingDuration : float;
                                       var human_voice_effect__endCoughingAt : float&;
                                       var human_voice_effect__activeEffects : Object&)
  if eid == evt.victim && evt.damageType == int(DamageType DM_GAS)
    human_voice_effect__endCoughingAt = get_sync_time() + human_voice_effect__coughingDuration
    human_voice_effect__activeEffects |> set("cough", true)


[es(tag=sound, before=human_breath_sound_base_update)]
def human_voice_effect_coughing_update(info : ParallelUpdateFrameDelayed;
                                       var human_voice_effect__endCoughingAt : float&;
                                       var human_voice_effect__activeEffects : Object&)
  if human_voice_effect__endCoughingAt > 0. && info.curTime >= human_voice_effect__endCoughingAt
    human_voice_effect__endCoughingAt = 0.
    human_voice_effect__activeEffects |> set("cough", false)
