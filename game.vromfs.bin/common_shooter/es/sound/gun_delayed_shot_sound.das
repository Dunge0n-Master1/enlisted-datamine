require ecs
require app
require common_shooter.events_common_shooter
require soundEvent


[es(tag=sound, REQUIRE=gunSound, after=human_gun_delayed_shot_update)]
def gun_delayed_shot_sound(evt : CmdWeapPhysUpdate;
                           gun_delayed_shot__delayTime : float;
                           gun_delayed_shot_sound__path : string;
                           gun_delayed_shot_sound__nextTime : float;
                           var gun_delayed_shot_sound__event : SoundEvent&;
                           gun__owner : EntityId)
  let play = gun_delayed_shot__delayTime > 0. && get_sync_time() > gun_delayed_shot_sound__nextTime
  if gun_delayed_shot_sound__event.enabled != play
    gun_delayed_shot_sound__event.enabled = play
    abandon(gun_delayed_shot_sound__event.handle)
    if gun_delayed_shot_sound__event.enabled
      query(gun__owner) <| $ [es] (transform : float3x4)
        gun_delayed_shot_sound__event |> play(gun_delayed_shot_sound__path, transform[3])
  elif gun_delayed_shot_sound__event.enabled
    query(gun__owner) <| $ [es] (transform : float3x4)
      set_pos(gun_delayed_shot_sound__event.handle, transform[3])


[es(tag=sound, REQUIRE=gunSound, on_event=(EventShot, CmdNetShot))]
def gun_delayed_shot_sound_on_shot(evt : Event;
                                   gun_delayed_shot_sound__cooldown : float;
                                   var gun_delayed_shot_sound__nextTime : float&;
                                   var gun_delayed_shot_sound__event : SoundEvent&)
  gun_delayed_shot_sound__event.enabled = false
  abandon(gun_delayed_shot_sound__event.handle)
  gun_delayed_shot_sound__nextTime = get_sync_time() + gun_delayed_shot_sound__cooldown
