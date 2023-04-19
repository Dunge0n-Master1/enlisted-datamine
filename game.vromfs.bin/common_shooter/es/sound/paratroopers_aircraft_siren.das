require ecs
require math.base
require soundEvent


[es(tag=sound, on_appear, after=paratroopers_aircraft_set_kick_distance)]
def paratroopers_aircraft_siren_appear(evt : Event;
                                       var paratroopers_aircraft_siren__distToStartSq : float&;
                                       paratroopers_aircraft_siren__distToStartOffset : float;
                                       ai_aircraft__distToKickParatroopers : float)
  paratroopers_aircraft_siren__distToStartSq = square(sqrt(ai_aircraft__distToKickParatroopers) + paratroopers_aircraft_siren__distToStartOffset)


[es(tag=sound, REQUIRE=vehicleWithWatched, no_order)]
def paratroopers_aircraft_siren_update(info : UpdateStageInfoAct;
                                       var paratroopers_aircraft_siren__event : SoundEvent&;
                                       paratroopers_aircraft_siren__path : string;
                                       paratroopers_aircraft_siren__distToStartSq : float;
                                       paratroopers_aircraft__kicked : bool;
                                       ai_aircraft__targetPos : float3;
                                       transform : float3x4)
  let enabled = paratroopers_aircraft_siren__event.enabled || (!paratroopers_aircraft__kicked && distance_sq(transform[3].xz, ai_aircraft__targetPos.xz) < paratroopers_aircraft_siren__distToStartSq)
  if paratroopers_aircraft_siren__event.enabled != enabled
    paratroopers_aircraft_siren__event.enabled = enabled
    abandon(paratroopers_aircraft_siren__event.handle)
    if paratroopers_aircraft_siren__event.enabled
      paratroopers_aircraft_siren__event |> play(paratroopers_aircraft_siren__path, transform[3])


[es(tag=sound, on_disappear, REQUIRE=vehicleWithWatched)]
def paratroopers_aircraft_siren_disappear(evt : Event;
                                          var paratroopers_aircraft_siren__event : SoundEvent&)
  abandon(paratroopers_aircraft_siren__event.handle)
  paratroopers_aircraft_siren__event.enabled = false
