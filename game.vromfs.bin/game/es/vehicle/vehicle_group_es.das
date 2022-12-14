require ecs
require net
require matching
require DagorSystem
require DagorDataBlock
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events

[es(tag=server)]
def vehicle_set_group_on_spawn_es(evt : CmdUseVehicleOnSpawn; player__limitVehicleByGroup : bool; origGroupId : int64)
  query(evt.vehicle) <| $ [es] (var vehicle_seats__restrictToGroup : int64&)
    vehicle_seats__restrictToGroup = player__limitVehicleByGroup ? origGroupId : int64(INVALID_GROUP_ID)

[es(tag=server, track=player__limitVehicleByGroup)]
def vehicle_set_group_on_limit_es(evt : Event; respawner__squad : EntityId; player__limitVehicleByGroup : bool; origGroupId : int64)
  find_query() <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=deadEntity)] (ownedBySquad : EntityId; var vehicle_seats__restrictToGroup : int64&)
    if respawner__squad == ownedBySquad
      vehicle_seats__restrictToGroup = player__limitVehicleByGroup ? origGroupId : int64(INVALID_GROUP_ID)
      return true
    return false

[es(tag=server, track=squad__isAlive)]
def vehicle_remove_group_on_squad_die_es(evt : Event; eid : EntityId; squad__isAlive : bool)
  if squad__isAlive
    return
  find_query() <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=deadEntity)] (ownedBySquad : EntityId; var vehicle_seats__restrictToGroup : int64&)
    if eid == ownedBySquad
      vehicle_seats__restrictToGroup = int64(INVALID_GROUP_ID)
      return true
    return false

[es(tag=server)]
def server_set_vehicle_limit_by_group_es(evt : CmdLimitVehicleByGroup; var player__limitVehicleByGroup : bool&)
  player__limitVehicleByGroup = evt.isLimited

[es(tag=gameClient, on_appear, REQUIRE=localPlayer)]
def user_set_vehicle_limit_by_group_es(evt : Event; eid : EntityId; player__limitVehicleByGroup : bool)
  dgs_get_settings() |> datablock_get_block("gameplay") <| $(blk)
    let isLimited = blk |> datablock_getBool("limit_vehicle_by_group", player__limitVehicleByGroup)
    send_net_event(eid, [[CmdLimitVehicleByGroup isLimited=isLimited]])
