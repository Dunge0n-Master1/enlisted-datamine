require ecs
require ecs.ecs_quirrel
require game.es.respawn_base_common
require daslib/quirrel_boost

def public pushValue(var vm : SQVM?; val : RespawnBaseType)
  sq_newtable(vm)
  if !empty(val.canUseRespawnbaseType)
    _::pushValue(vm, "canUseRespawnbaseType")
    _::pushValue(vm, val.canUseRespawnbaseType)
    sq_rawset(vm, -3l)
    _::pushValue(vm, "canUseRespawnbaseSubtypes")
    _::pushValue(vm, val.canUseRespawnbaseSubtypes)
    sq_rawset(vm, -3l)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team(team : int)
  return respawn_base_common::find_respawn_base_for_team(team)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team_with_type(team : int; resp_type : string; subtypes : array<string>)
  return respawn_base_common::find_respawn_base_for_team_with_type(team, resp_type, subtypes)

[quirrel_bind(module_name="das.respawn")]
def find_respawn_base_for_team_with_type_of_group(team : int; resp_type : string; subtypes : array<string>; group : int)
  return respawn_base_common::find_respawn_base_for_team_with_type(team, resp_type, subtypes, group)

[quirrel_bind(module_name="das.respawn")]
def find_human_respawn_base(team : int; safest : bool)
  return respawn_base_common::find_human_respawn_base(team, safest)

[quirrel_bind(module_name="das.respawn")]
def count_vehicles_of_type(count_team : int; respawnbase_type : string)
  return respawn_base_common::count_vehicles_of_type(count_team, respawnbase_type)

[quirrel_bind(module_name="das.respawn")]
def is_vehicle_spawn_allowed_by_limit(team : int; resp_type : string)
  return respawn_base_common::is_vehicle_spawn_allowed_by_limit(team, resp_type)

[quirrel_bind(module_name="das.respawn")]
def get_can_use_respawnbase_type(templ_name : string)
  return <- respawn_base_common::get_can_use_respawnbase_type(templ_name)

[quirrel_bind(module_name="das.respawn")]
def is_respawn_at_team_side(spawn_pos : float3; zone_pos : float3; team : int)
  return respawn_base_common::is_respawn_at_team_side(spawn_pos, zone_pos, team)

[quirrel_bind(module_name="das.respawn")]
def check_exists_navmesh_path_from_respawn_to_capzone(respawnPointEid : EntityId; pos : float3; pos_end : float3)
  return respawn_base_common::check_exists_navmesh_path_from_respawn_to_capzone(respawnPointEid, pos, pos_end)
