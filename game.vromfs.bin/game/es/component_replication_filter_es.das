options no_global_variables = false
require ecs
require EnlistedNet
require DagorSystem

var // these variables keep constant values that don't change at runtime (after set), variables for non constant values are prohibited
  filterPossessed : uint8
  filterNotPossessed : uint8
  filterPossessedAndSpectated : uint8
  filterPossessedSquadOrSpectatedSquad : uint8
  filterPossessedSpectatedAndAttachables : uint8
  filterPossessedVehicle : uint8
  filterPossessedAndSpectatedVehicle : uint8
  filterPossessedSpectatedAttachablesAndVehicle : uint8
  filterPossessedTeamSpectatedAttachablesAndVehicle : uint8

def find_component_filter_check(name : string)
  let res = find_component_filter(name)
  if int(res) == int(replicate_everywhere_filter_id) // workaround aot issue error: no matching function for call to 'das_nequ_val' DAS_ASSERT((das_nequ_val(__res_rename_at_18,0x0)));
    logerr("Unable to find component filter '{name}'")
  return res

[es(tag=server, on_appear, REQUIRE=msg_sink)]
def filter_creation_track(evt : Event)
  filterPossessed = find_component_filter_check("filter_possessed")
  filterNotPossessed = find_component_filter_check("filter_not_possessed")
  filterPossessedAndSpectated = find_component_filter_check("filter_possessed_and_spectated")
  filterPossessedSquadOrSpectatedSquad = find_component_filter_check("filter_possessed_squad_and_spectated_squad")
  filterPossessedSpectatedAndAttachables = find_component_filter_check("filter_possessed_spectated_and_attachables")
  filterPossessedSpectatedAttachablesAndVehicle = find_component_filter_check("filter_possessed_spectated_attachables_and_vehicle")
  filterPossessedTeamSpectatedAttachablesAndVehicle = find_component_filter_check("filter_possessed_team_spectated_attachables_and_vehicle")
  filterPossessedVehicle = find_component_filter_check("filter_possessed_vehicle")
  filterPossessedAndSpectatedVehicle = find_component_filter_check("filter_possessed_and_spectated_vehicle")

[es(tag=server, track=possessed, REQUIRE=possessed)]
def on_change_possesed_es(evt : Event)
  update_component_filter_event(filterPossessed)
  update_component_filter_event(filterNotPossessed)
  update_component_filter_event(filterPossessedAndSpectated)
  update_component_filter_event(filterPossessedSquadOrSpectatedSquad)
  update_component_filter_event(filterPossessedSpectatedAndAttachables)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedTeamSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)

[es(tag=server, track=specTarget, REQUIRE=specTarget)]
def on_change_spectator_target_es(evt : Event)
  update_component_filter_event(filterPossessedAndSpectated)
  update_component_filter_event(filterPossessedSquadOrSpectatedSquad)
  update_component_filter_event(filterPossessedSpectatedAndAttachables)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedTeamSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)

[es(tag=server, track=human_anim__vehicleSelected, REQUIRE=human_anim__vehicleSelected)]
def on_change_vehicle_selected_es(evt : Event)
  update_component_filter_event(filterPossessedVehicle)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedTeamSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)
