module net_utils shared

require ecs
require game.utils.team
require EnlistedNet
require player

def enum_connections_squad(squad_eid : EntityId) : array<IConnection?>
  var recipients : array<IConnection?>
  if !!squad_eid
    query() <| $ [es(REQUIRE=player)] (possessed : EntityId; connid : int; disconnected : bool)
      if !disconnected && doesEntityExist(possessed) && (possessed |> get_Eid("squad_member__squad") ?? INVALID_ENTITY_ID) == squad_eid
        recipients |> push(connid |> get_client_connection())
  return <- recipients

def enum_connections_vehicle(vehicle_eid : EntityId) : array<IConnection?>
  var recipients : array<IConnection?>
  if !!vehicle_eid
    query() <| $ [es(REQUIRE=player)] (possessed : EntityId; connid : int; disconnected : bool)
      if !disconnected && doesEntityExist(possessed) && (possessed |> get_Eid("human_anim__vehicleSelected") ?? INVALID_ENTITY_ID) == vehicle_eid
        recipients |> push(connid |> get_client_connection())
  return <- recipients

def enum_connections_range_team(pos : float3;
                                search_range : float;
                                team_id : int;
                                filter_possessed : bool;
                                except_possessed : EntityId;
                                is_player_relative : bool) : array<IConnection?>
  var recipients : array<IConnection?>
  query() <| $ [es(REQUIRE=player)] (eid : EntityId; possessed : EntityId; connid : int; disconnected : bool)
    if (filter_possessed && possessed == except_possessed) || disconnected
      return
    if search_range > 0.f
      if is_player_relative
        let playerLat : LookingAt = player_get_looking_at(eid)
        let playerPos : float3 const? = playerLat.pos
        if playerPos == null || length_sq(pos - *playerPos) > (search_range * search_range)
          return
      elif !doesEntityExist(possessed)
        return
      else
        let possessedTm = possessed |> get_TMatrix("transform") ?? float3x4()
        if length_sq(pos - possessedTm[3]) > (search_range * search_range)
          return
    if team_id != TEAM_UNASSIGNED && (get_int(possessed, "team") ?? TEAM_UNASSIGNED) != team_id
      return
    recipients |> push(connid |> get_client_connection())
  return <- recipients

def private entity_pos_range_team_impl(target : EntityId; default_bcast_range : float; team_eid : EntityId;
                                       filter_possessed : bool; except_possessed : EntityId; is_player_relative : bool) : array<IConnection?>
  let targetTm : float3x4 = target |> get_TMatrix("transform") ?? float3x4()
  let team : int = get_int(team_eid, "team") ?? TEAM_UNASSIGNED
  let searchRange : float = target |> get_float("bcastRange") ?? default_bcast_range
  return <- enum_connections_range_team(targetTm[3], searchRange, team, filter_possessed, except_possessed, is_player_relative);

def target_entity_pos_range(target : EntityId; default_bcast_range : float = 25.f; is_player_relative : bool = false) : array<IConnection?>
  return <- entity_pos_range_team_impl(target, default_bcast_range, INVALID_ENTITY_ID, false, INVALID_ENTITY_ID, is_player_relative)

def target_entity_pos_range_team(target : EntityId; default_bcast_range : float = 25.f; is_player_relative : bool = false) : array<IConnection?>
  return <- entity_pos_range_team_impl(target, default_bcast_range, target, false, INVALID_ENTITY_ID, is_player_relative)

def target_entity_pos_range_except_hero(target : EntityId; default_bcast_range : float = 25.f; is_player_relative : bool = false) : array<IConnection?>
  return <- entity_pos_range_team_impl(target, default_bcast_range, INVALID_ENTITY_ID, true, target, is_player_relative)

def private get_controlled_by_connection(var out : array<IConnection?>&; eid : EntityId)
  query(eid) <| $ [es] (replication : NetObject)
    out |> push(replication |> net_object_getControlledBy() |> get_client_connection())

def target_entity_conn(target_entity : EntityId) : array<IConnection?>
  var recipients : array<IConnection?>
  get_controlled_by_connection(recipients, target_entity)
  return <- recipients

def entity_team(target_entity : EntityId) : array<IConnection?>
  let teamId : int = get_int(target_entity, "team") ?? TEAM_UNASSIGNED
  var recipients : array<IConnection?>
  query() <| $ [es(REQUIRE=player)] (possessed : EntityId; connid : int; disconnected : bool)
    if !disconnected && doesEntityExist(possessed) && (get_int(possessed, "team") ?? TEAM_UNASSIGNED) == teamId
      recipients |> push(connid |> get_client_connection())
  return <- recipients

def target_entity_squad(target : EntityId) : array<IConnection?>
  return <- enum_connections_squad(target |> get_Eid("squad_member__squad") ?? INVALID_ENTITY_ID);

def target_entity_vehicle(target : EntityId) : array<IConnection?>
  return <- enum_connections_vehicle(target |> get_Eid("human_anim__vehicleSelected") ?? INVALID_ENTITY_ID);

def possessed_and_spectated(target_entity : EntityId) : array<IConnection?>
  var recipients : array<IConnection?>
  get_controlled_by_connection(recipients, target_entity)
  query() <| $ [es(REQUIRE=player)] (possessed : EntityId; connid : int; disconnected : bool; specTarget : EntityId)
    if specTarget == target_entity && possessed != target_entity && !disconnected && doesEntityExist(possessed)
      recipients |> push(connid |> get_client_connection())
  return <- recipients

def possessed_and_spectated_player(target_entity : EntityId) : array<IConnection?>
  let possessedByTarget : EntityId = get_Eid(target_entity, "possessed") ?? INVALID_ENTITY_ID
  return <- possessed_and_spectated(possessedByTarget)
