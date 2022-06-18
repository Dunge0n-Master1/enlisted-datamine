module player_utils shared
require ecs

let
  UNINITIALIZED_GROUP = int64(0)

def is_same_player_groups(group_a, group_b : int64) : bool
  return group_a != UNINITIALIZED_GROUP && group_a == group_b

def is_players_in_same_group(player_a, player_b : EntityId) : bool
  let groupA = get_int64(player_a, "groupId") ?? UNINITIALIZED_GROUP
  let groupB = get_int64(player_b, "groupId") ?? UNINITIALIZED_GROUP
  return is_same_player_groups(groupA, groupB)