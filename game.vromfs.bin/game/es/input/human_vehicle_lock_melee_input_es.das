require ecs

[es(tag=input, track=(human_vehicle__occupiedSeatEid, human_vehicle__isHoldingGunPassenger), on_appear, before=human_input_es)]
def human_lock_shoot_in_vehicle_es(evt : Event;
                                   human_vehicle__occupiedSeatEid : EntityId;
                                   human_vehicle__isHoldingGunPassenger : bool;
                                   var human_input__canShoot : bool&)
  human_input__canShoot = true

  query(human_vehicle__occupiedSeatEid) <| $ [es] (seat_anim__fireReadyUpper : das_string const?)
    human_input__canShoot = seat_anim__fireReadyUpper != null && human_vehicle__isHoldingGunPassenger
