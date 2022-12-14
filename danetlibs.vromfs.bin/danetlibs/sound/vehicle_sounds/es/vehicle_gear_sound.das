require ecs
require vehicle
require sound_utils.modules.sound_player_common

[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(vehicle_phys_es, sound_control_update))]
def vehicle_gear_sound(evt : Event;
                       sound_control__shouldPlay : bool;
                       vehicle_net_phys : VehiclePhysActor;
                       var vehicle_gear_sound__gear : int&;
                       [[shared_comp]] vehicle_gear_sound__path : Object;
                       is_watched_sound : bool;
                       sound_tags : Object;
                       transform : float3x4)
  if sound_control__shouldPlay && vehicle_gear_sound__gear != int(vehicle_net_phys.phys.currentState.currentGear) && vehicle_gear_sound__gear >= 0
    sound_player_common::play_path(vehicle_gear_sound__path, sound_tags, is_watched_sound, transform[3])
  vehicle_gear_sound__gear = int(vehicle_net_phys.phys.currentState.currentGear)
