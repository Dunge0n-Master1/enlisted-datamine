require ecs
require app
require soundEvent
require math.base
require sound_utils_net.modules.sound_utils_net_events

[es(tag=sound, on_appear)]
def artillery_siren_appear(evt : Event;
                           artillery_siren__startDelay : float;
                           var artillery_siren__startAt : float&)
  artillery_siren__startAt = get_sync_time() + artillery_siren__startDelay

[es(tag=sound, no_order)]
def artillery_siren_update(info : ParallelUpdateFrameDelayed;
                           var artillery_siren__active : bool&;
                           artillery_siren__startAt : float;
                           artillery__targetPos : float3;
                           artillery_siren__targetRadius : float;
                           artillery_siren__path : string)
  if !artillery_siren__active && info.curTime >= artillery_siren__startAt
    find_query() <| $ [es(REQUIRE=requested_aircraft)] (transform : float3x4)
      if length_sq(transform[3].xz - artillery__targetPos.xz) < square(artillery_siren__targetRadius)
        oneshot(artillery_siren__path, artillery__targetPos)
        artillery_siren__active = true
        return true
      return false
