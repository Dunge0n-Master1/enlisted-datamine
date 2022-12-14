require ecs
require common_shooter.dm_events
require sound_utils.modules.sound_player_common


[es(tag=sound)]
def vehicle_projectile_hit_sound(evt : EventOnHitByProjectile;
                                 sound_control__shouldPlay : bool;
                                 is_watched_sound : bool;
                                 [[shared_comp]] vehicle_projectile_hit_sound__hitPath : Object;
                                 [[shared_comp]] vehicle_projectile_hit_sound__hitSmallPath : Object;
                                 vehicle_projectile_hit_sound__smallCaliberThreshold : float;
                                 sound_tags : Object;
                                 transform : float3x4)
  if sound_control__shouldPlay
    let isSmallCaliber = evt.caliber <= vehicle_projectile_hit_sound__smallCaliberThreshold
    sound_player_common::play_path(isSmallCaliber ? vehicle_projectile_hit_sound__hitSmallPath : vehicle_projectile_hit_sound__hitPath, sound_tags, is_watched_sound, transform * evt.localHitPos)
