module vehicle_turret_common shared
require ecs
require vehicle

def can_control_turret(turret_mask : int; turret_no : int)
  return (turret_mask & (1 << turret_no)) != 0

def get_turret_control_mask(seat_eids : EidList)
  var turretsMask = 0
  for seatEid in seat_eids
    query(seatEid) <| $ [es] (seat__ownerControls : VehicleControlsState)
      turretsMask |= int(seat__ownerControls.turretsMask)
  return turretsMask