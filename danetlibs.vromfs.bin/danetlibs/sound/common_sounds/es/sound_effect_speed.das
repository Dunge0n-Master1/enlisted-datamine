require ecs
require soundEvent
require DagorMath

[es(tag=sound, no_order)]
def sound_effect_speed(info : UpdateStageInfoAct;
                       var sound_effect_speed__pos : float3&;
                       sound_effect_speed__speedToVar : float4;
                       sound_effect__event : SoundEvent;
                       transform : float3x4)
  let speed = safediv(length(transform[3] - sound_effect_speed__pos), info.dt)
  sound_effect_speed__pos = transform[3]
  set_var(sound_effect__event.handle, "speed", cvt(speed, sound_effect_speed__speedToVar.x, sound_effect_speed__speedToVar.y, sound_effect_speed__speedToVar.z, sound_effect_speed__speedToVar.w))
