require ecs
require app
require enlisted.events_enlisted

[es(tag=sound, no_order, REQUIRE=watchedVehicleSound, REQUIRE=watchedByPlr)]
def watched_vehicle_sound_update_watched(info : ParallelUpdateFrameDelayed;
                                         var is_watched_sound : bool&)
  is_watched_sound = true


[es(tag=sound, no_order, REQUIRE=watchedVehicleSound, REQUIRE_NOT=watchedByPlr)]
def watched_vehicle_sound_update_not_watched(info : ParallelUpdateFrameDelayed;
                                             vehicle_seats__seatEids : EidList?;
                                             var is_watched_sound : bool&)
  is_watched_sound = false
  if vehicle_seats__seatEids != null
    for seatEid in *vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
        is_watched_sound ||= has(seat__ownerEid, "watchedByPlr")
