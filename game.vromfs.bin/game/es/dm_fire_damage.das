require ecs
require app

[es(tag=server, track=fire_damage__isBurn)]
def dm_fire_damage_track_is_burn(evt : Event; fire_damage__isBurn : bool; var fire_damage__startTime : float&)
  fire_damage__startTime = fire_damage__isBurn ? get_sync_time() : -1.0
