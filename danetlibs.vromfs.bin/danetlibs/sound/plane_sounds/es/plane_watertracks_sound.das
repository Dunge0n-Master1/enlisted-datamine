require ecs
require soundEvent
require soundSystem
require EnlistedPlane


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(plane_phys_es, sound_control_update, vehicle_sound_update_speed))]
def plane_watertracks_sound(evt : Event;
                            sound_control__shouldPlay : bool;
                            plane_net_phys : PlaneActor;
                            plane_watertracks_sound__path : string;
                            var plane_watertracks_sound__event : SoundEvent&;
                            vehicle_sound_vars__speed : float;
                            transform : float3x4)
  let shouldPlay = sound_control__shouldPlay && plane_net_phys.phys.Gears.onWater
  if plane_watertracks_sound__event.enabled != shouldPlay
    plane_watertracks_sound__event.enabled = shouldPlay
    abandon(plane_watertracks_sound__event.handle)
    if plane_watertracks_sound__event.enabled
      plane_watertracks_sound__event |> play(plane_watertracks_sound__path, transform[3])

  if plane_watertracks_sound__event.enabled
    set_var(plane_watertracks_sound__event.handle, "speed", vehicle_sound_vars__speed)
    set_pos(plane_watertracks_sound__event.handle, transform[3])
