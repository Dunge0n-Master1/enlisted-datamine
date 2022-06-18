require ecs
require ecs.common
require app
require dm
require game.es.vehicle.vehicle_events
require game.utils.team
require common_shooter.events_common_shooter

struct EngineerInfo
  eid : EntityId = INVALID_ENTITY_ID
  player : EntityId = INVALID_ENTITY_ID
  guid : string = ""
  buildingEid : EntityId = INVALID_ENTITY_ID

def get_builder(eid : EntityId) : EngineerInfo
  var res : EngineerInfo
  query(eid) <| $ [es] (buildByPlayer : EntityId; buildByEngineerEid : EntityId; builder_info__guid : string)
    res.eid = buildByEngineerEid
    res.player = buildByPlayer
    res.guid = builder_info__guid
    res.buildingEid = eid
  return res

def get_engineer_info_from_offender(eid : EntityId) : EngineerInfo
  var builderInfo : EngineerInfo
  query(eid) <| $ [es] (human_anim__vehicleSelected : EntityId; human_attached_gun__attachedGunEid : EntityId)
    builderInfo = get_builder(human_anim__vehicleSelected)
    if builderInfo.guid == ""
      builderInfo = get_builder(human_attached_gun__attachedGunEid)
  return builderInfo

def is_valid_assist(builder : EngineerInfo; offender_eid : EntityId)
  var res : EngineerInfo
  query(offender_eid) <| $ [es] (team aka offender_team : int;
                                 squad_member__playerEid aka offender_squad_member__playerEid : EntityId)
    query(builder.player) <| $ [es] (team : int = TEAM_UNASSIGNED)
      if offender_squad_member__playerEid != builder.player && is_teams_friendly(team, offender_team)
        res = builder
  return res.guid != ""

def put_engineer_assist_data_from_offender(offender : EntityId; engineer : EngineerInfo; var last_offenders__engineerAssists : Object&)
  let time = get_sync_time()
  if engineer.guid != ""
    push_to_object(last_offenders__engineerAssists, "{offender}") <| $(var info : Object#)
      set(info, "time", time)
      set(info, "eid", engineer.eid)
      set(info, "playerEid", engineer.player)
      set(info, "guid", engineer.guid)

[es(tag=server, REQUIRE_NOT=deadEntity)]
def vehicle_damaged_with_engineer_gun(evt : EventOnPartDamaged;
                                      team : int = TEAM_UNASSIGNED;
                                      var last_offenders__engineerAssists : Object&;
                                      var last_offender__builtGunEid : EntityId&)
  assume offender = evt.hitData.offender
  let builder = get_engineer_info_from_offender(offender)
  if !!offender && !is_teams_friendly(get_int(offender, "team") ?? TEAM_UNASSIGNED, team)
    last_offender__builtGunEid = builder.buildingEid
  if is_valid_assist(builder, offender)
    put_engineer_assist_data_from_offender(offender, builder, last_offenders__engineerAssists)

[es(tag=server)]
def soldier_damaged_with_engineer_gun(evt : EventOnEntityHit) // broadcast
  query(evt.victim) <| $ [es] (var last_offenders__engineerAssists : Object&; var death_desc__builtGunEid : EntityId&)
    let builder = get_engineer_info_from_offender(evt.offender)
    death_desc__builtGunEid = builder.buildingEid
    if is_valid_assist(builder, evt.offender)
      put_engineer_assist_data_from_offender(evt.offender, builder, last_offenders__engineerAssists)