module turrets_common shared
require ecs
require ecs.common
require vehicle
require EnlistedWeapon

struct GunOwner
  eid : EntityId = INVALID_ENTITY_ID
  isPlayer : bool = false

def find_gun_owner(turret_no, seat_eids)
  var gunOwner = GunOwner()
  for seatEid in seat_eids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__ownerControls : VehicleControlsState; seat__isPlayer : bool)
      if can_control_turret(seat__ownerControls, turret_no)
        gunOwner.eid = seat__ownerEid
        gunOwner.isPlayer = seat__isPlayer
  return gunOwner

def find_turret_index_by_name(turret_control__turretInfo : Array; turret_name : string) : int
  if turret_name == ""
    return -1
  return find_index_if(each(turret_control__turretInfo)) <| $(elem) : bool
    return get_string(get_ecs_object(elem), "turretName", "") == turret_name