require ecs
require game.es.events
require game.events_game

[es(tag=server)]
def kill_crew_on_player_death(evt : EventEntityDied; possessedByPlr, human_anim__vehicleSelected : EntityId)
  if !possessedByPlr
    return
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE=killCrewOnPlayerDeath)] (vehicle_seats__seatEids : EidList)
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
        sendEvent(seat__ownerEid, [[CmdKill offender=evt.offender, damageType=uint16(evt.damageType), gunPropsId=evt.gunPropsId, shellId=evt.shellId]])
