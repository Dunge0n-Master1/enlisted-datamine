require ecs
require vehicle

[es(tag=sound, track=isInVehicle)]
def plane_fall_cry_sound_disabler(evt : Event; human_anim__vehicleSelected, vehicle__lastEid : EntityId;
                                  isInVehicle : bool; var human_voice_effect_fallcry__enabled : bool&)
  if isInVehicle && has(human_anim__vehicleSelected, "airplane")
    human_voice_effect_fallcry__enabled = false
  elif !isInVehicle && has(vehicle__lastEid, "airplane")
    human_voice_effect_fallcry__enabled = true
