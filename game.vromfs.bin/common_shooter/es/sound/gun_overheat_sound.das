require ecs
require soundEvent
require DagorMath
require enlisted.events_enlisted


[es(tag=sound, after=gun_overheat_es)]
def gun_overheat_sound(info : ParallelUpdateFrameDelayed;
                       gun_sound__isWatched : bool;
                       gun__overheat : float;
                       gun_overheat_sound__path : string;
                       gun_overheat_sound__gunOverheatToVar : float4;
                       var gun_overheat_sound__event : SoundEvent&)

  let heat = gun_sound__isWatched ? cvt(gun__overheat,
                                        gun_overheat_sound__gunOverheatToVar.x, gun_overheat_sound__gunOverheatToVar.y,
                                        gun_overheat_sound__gunOverheatToVar.z, gun_overheat_sound__gunOverheatToVar.w) : 0.
  let shouldPlay = heat > 0.
  if gun_overheat_sound__event.enabled != shouldPlay
    gun_overheat_sound__event.enabled = shouldPlay
    abandon(gun_overheat_sound__event.handle)
    if shouldPlay
      gun_overheat_sound__event |> play(gun_overheat_sound__path)
  if gun_overheat_sound__event.enabled
    set_var(gun_overheat_sound__event.handle, "heat", heat)
