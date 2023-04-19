require ecs
require DngShip
require Ship
require vehicle
require DagorMath
require math.base

[es(tag=server, no_order)]
def anchor_after_stopping(
                          info : UpdateStageInfoAct;
                          auto_anchor__minSpeedForAnchor, auto_anchor__delay : float;
                          vehicle_seats__seatEids : EidList;
                          var auto_anchor__nextAnchorTime : float&;
                          var ship_net_phys : ShipActor)

  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid != INVALID_ENTITY_ID
      auto_anchor__nextAnchorTime = 0f
      ship_phys_set_anchor(ship_net_phys.phys, false)
      return

  let lowSpeed = length_sq(ship_net_phys.phys.currentState.velocity) <= square(auto_anchor__minSpeedForAnchor)
  if !lowSpeed
    auto_anchor__nextAnchorTime = 0f
    ship_phys_set_anchor(ship_net_phys.phys, false)
    return

  if auto_anchor__nextAnchorTime <= 0f
    auto_anchor__nextAnchorTime = info.curTime + auto_anchor__delay
    return

  if info.curTime >= auto_anchor__nextAnchorTime
    auto_anchor__nextAnchorTime = 0f
    ship_phys_set_anchor(ship_net_phys.phys, true)
