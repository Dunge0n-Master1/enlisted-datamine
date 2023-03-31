require ecs
require ecs.common
require app
require vehicle_sounds_net.modules.vehicle_sounds_net_events
require sound_utils.modules.sound_player_common
require sound_utils_net.modules.sound_utils_net_events
require soundEvent
require soundHash


[es(tag=sound)]
def vehicle_horn_toggle(evt : CmdVehicleSoundHorn;
                        sound_control__shouldPlay : bool;
                        var vehicle_horn_sound__endTime : float&;
                        vehicle_horn_sound__note : int;
                        [[shared_comp]] vehicle_horn_sound__path : Object;
                        sound_tags : Object;
                        var sound_event_group : SoundEventGroup&;
                        is_watched_sound : bool;
                        transform : float3x4)
  if sound_control__shouldPlay
    if evt.enable && evt.end > 0.
      let h = sound_player_common::play_path(vehicle_horn_sound__path, sound_tags, is_watched_sound, transform[3], sound_hash("horn"), sound_event_group)
      set_var_optional(h, "note", float(vehicle_horn_sound__note))
      vehicle_horn_sound__endTime = evt.end
    else
      reject_sound(sound_event_group, sound_hash("horn"))
      vehicle_horn_sound__endTime = 0.


[es(tag=sound, no_order)]
def vehicle_horn_reject(info : ParallelUpdateFrameDelayed;
                        var sound_event_group : SoundEventGroup&;
                        var vehicle_horn_sound__endTime : float&)
  if vehicle_horn_sound__endTime > 0.
    if info.curTime >= vehicle_horn_sound__endTime
      reject_sound(sound_event_group, sound_hash("horn"))
      vehicle_horn_sound__endTime = 0.
