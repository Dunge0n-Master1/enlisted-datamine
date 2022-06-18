require ecs
require app
require soundEvent
require soundSystem
require sound_utils.modules.sound_player_common
require sound_utils_net.modules.sound_desc_common
require vehicle_sounds_net.modules.vehicle_sounds_net_events

[es(tag=sound)]
def play_vehicle_damage_sound(evt : CmdPlayVehicleDamageSound;
                              sound_control__enabled : bool;
                              [[shared_comp]] vehicle_damage_sound__paths : Object;
                              sound_tags : Object;
                              is_watched_sound : bool;
                              vehicle_sound__maxNetLatency = 2.;
                              transform : float3x4)
  if sound_control__enabled
    if get_sync_time() < evt.time + vehicle_sound__maxNetLatency
      let path = find_desc_by_hash(evt.hash, vehicle_damage_sound__paths)
      if path != null
        sound_player_common::play_path(*path, sound_tags, is_watched_sound, transform[3])
      else
        sound_debug("there is no path '{evt.hash}' in vehicle_damage_sound__paths")
