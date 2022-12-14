require ecs
require soundEvent
require DagorMath
require sound_utils_net.modules.sound_desc_common
require common_shooter.es.sound.gun_sound_common


[es(tag=sound, after=gun_overheat_es, on_event=ParallelUpdateFrameDelayed)]
def gun_overheat_sound(evt : Event;
                       gun__owner : EntityId;
                       gun__overheat : float;
                       gun_overheat_sound__path : string;
                       gun_overheat_sound__gunOverheatToVar : float2;
                       var gun_overheat_sound__event : SoundEvent&)
  let shouldPlay = gun__overheat > gun_overheat_sound__gunOverheatToVar.x && is_watched_gun_sound(gun__owner)
  if gun_overheat_sound__event.enabled != shouldPlay
    gun_overheat_sound__event.enabled = shouldPlay
    abandon(gun_overheat_sound__event.handle)
    if shouldPlay
      gun_overheat_sound__event |> play(gun_overheat_sound__path)
  if gun_overheat_sound__event.enabled
    let heat = cvt(gun__overheat, gun_overheat_sound__gunOverheatToVar.x, gun_overheat_sound__gunOverheatToVar.y, 0., 1.)
    set_var(gun_overheat_sound__event.handle, "heat", heat)
