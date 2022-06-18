require ecs
require ecs.common
require app
require dm
require common_shooter.events_common_shooter
require game.utils.team

struct VehicleOffenderInfo
  eid : EntityId
  player : EntityId
  squad : EntityId
  guid : string

def get_assist_crew(vehicle_eid, offender_eid, offender_squad_eid : EntityId)
  var result : array<VehicleOffenderInfo>
  query(vehicle_eid) <| $ [es] (vehicle_seats__seatEids : EidList; ownedBySquad : EntityId)
    if ownedBySquad != offender_squad_eid
      return
    for seatEid in vehicle_seats__seatEids
      let crewMemberEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      if crewMemberEid == offender_eid
        continue
      query(crewMemberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__playerEid, squad_member__squad : EntityId; guid : string)
        if squad_member__squad == offender_squad_eid
          push(result, [[VehicleOffenderInfo eid=crewMemberEid, player=squad_member__playerEid, squad=squad_member__squad, guid=guid]])
  return <- result

def write_offender_info(eid, player_eid, squad_eid : EntityId; guid : string; time : float; is_crew : bool; var out_obj : Object&)
  push_to_object(out_obj, "{eid}") <| $(var offenderInfo : Object#)
    set(offenderInfo, "time", time)
    set(offenderInfo, "player", player_eid)
    set(offenderInfo, "squad", squad_eid)
    set(offenderInfo, "guid", guid)
    set(offenderInfo, "isCrew", is_crew)

[es(tag=server)]
def player_damaged_vehicle_event(evt : EventOnPartDamaged; team aka vehicle_team : int = TEAM_UNASSIGNED; var vehicleOffenders : Object&)
  let offender = evt.hitData.offender
  query(offender) <| $ [es] (possessedByPlr : EntityId; squad_member__squad : EntityId; guid : string; team aka offender_team : int = TEAM_UNASSIGNED)
    let offenderPlayer = possessedByPlr
    let offenderSquad = squad_member__squad
    let offenderGuid = guid
    if !offenderPlayer || is_teams_friendly(vehicle_team, offender_team)
      return
    let time = get_sync_time()
    write_offender_info(offender, offenderPlayer, offenderSquad, offenderGuid, time, false, vehicleOffenders)
    let vehicleEid = get_Eid(offender, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
    if !!vehicleEid
      for crewInfo in get_assist_crew(vehicleEid, offender, offenderSquad)
        write_offender_info(crewInfo.eid, crewInfo.player, crewInfo.squad, crewInfo.guid, time, true, vehicleOffenders)