require ecs
require EnlistedWalkerai
require game.es.vehicle.vehicle_seats_common


[es(REQUIRE=walker_agent, REQUIRE_NOT=deadEntity)]
def kick_walkers_from_vehicle_es(info : UpdateStageInfoAct;
                                 eid : EntityId;
                                 human_anim__vehicleSelected : EntityId;
                                 squad_member__squad : EntityId;
                                 squad_member__isPersonalOrder : bool;
                                 squad_member__orderType : int;
                                 squad_member__orderUseEntity : EntityId;
                                 isInVehicle : bool)
  if !isInVehicle || !squad_member__squad
    return

  var usedEntity : EntityId = INVALID_ENTITY_ID
  var squadLeader : EntityId = INVALID_ENTITY_ID
  query(squad_member__squad) <| $ [es] (squad__orderUseEntity : EntityId; squad__leader : EntityId = INVALID_ENTITY_ID)
    usedEntity = squad__orderUseEntity
    squadLeader = squad__leader

  if squad_member__isPersonalOrder && squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE)
    usedEntity = squad_member__orderUseEntity

  if usedEntity == human_anim__vehicleSelected
    return

  let walkerEid = eid
  query(human_anim__vehicleSelected) <| $ [es] (eid : EntityId; vehicle_seats__seatEids : EidList)
    var found = false
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__isPlayer : bool; seat__squadEid : EntityId = INVALID_ENTITY_ID)
        found = seat__squadEid == squad_member__squad && (seat__isPlayer || seat__ownerEid == squadLeader)
      if found
        return
    kick_from_vehicle(walkerEid, eid, vehicle_seats__seatEids)
