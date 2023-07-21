require ecs
require app
require vehicle
require game.es.squad_order_common
require enlisted.game.es.enlisted_squad_common
require game.es.vehicle.vehicle_events

[es(tag=server, track=burning__isBurning)]
def on_squad_member_exit_vehicle_on_burning(evt : Event;
                                            eid : EntityId;
                                            isAlive : bool;
                                            isInVehicle : bool;
                                            possessedByPlr : EntityId;
                                            human_anim__vehicleSelected : EntityId;
                                            squad_member__squad : EntityId;
                                            burning__isBurning : bool)
  if !burning__isBurning
    return
  if possessedByPlr != INVALID_ENTITY_ID
    return
  if !isAlive || !isInVehicle
    return

  let vehicleEid = human_anim__vehicleSelected
  if vehicleEid == INVALID_ENTITY_ID
    return

  if has(vehicleEid, "isTank")
    return
  if has(vehicleEid, "airplane")
    return

  query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
    if squad__leader == eid
      return
    query(squad__leader) <| $ [es] (isAlive : bool;
                                    isInVehicle : bool;
                                    human_anim__vehicleSelected : EntityId)
      if !isAlive || !isInVehicle || human_anim__vehicleSelected != vehicleEid
        query(squad_member__squad) <| $ [es] (squad__orderType : int;
                                              squad__orderUseEntity : EntityId)
          if squad__orderType == int(SquadOrder ESO_USE_VEHICLE) && squad__orderUseEntity == vehicleEid
            reset_squad_order(squad_member__squad)

        query(eid) <| $ [es] (squad_member__orderType : int;
                              squad_member__orderUseEntity : EntityId)
          if squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE) && squad_member__orderUseEntity == vehicleEid
            reset_squad_mate_order(eid)

        sendEvent(vehicleEid, [[CmdKickFromVehicle eid=eid]])
