module player_group_common shared

require ecs
require ecs.common
require matching

let INVALID_GROUP_ID_INT64 = int64(INVALID_GROUP_ID)

def is_bot_auto_squad()
  return find_query() <| $ [es] (bots_ai_spawner__botAutoSquad : bool)
    return bots_ai_spawner__botAutoSquad

def find_best_available_group_for_bot(team; exclude_group_id = INVALID_GROUP_ID_INT64)
  var groupEid = INVALID_ENTITY_ID
  var minPlayersInGroup = -1
  query() <| $ [es] (eid : EntityId;
                     player_group__id : int64;
                     player_group__wishTeam : int;
                     player_group__maxBotPlayers : int;
                     player_group__members : ecs::UInt64List)
    if player_group__wishTeam != team || player_group__id == INVALID_GROUP_ID_INT64 || player_group__id == exclude_group_id
      return
    if minPlayersInGroup == -1
      minPlayersInGroup = player_group__maxBotPlayers
    let membersInGroup = length(player_group__members)
    if membersInGroup < minPlayersInGroup
      minPlayersInGroup = membersInGroup
      groupEid = eid
  return groupEid

def define_bot_in_group(bot_eid; exclude_group_id = INVALID_GROUP_ID_INT64)
  ecs::query(bot_eid) <| $ [es(REQUIRE=playerIsBot)] (team : int;
                                                      var groupId : int64&;
                                                      var player_group__memberIndex : int&)
    let bestGroupEid = find_best_available_group_for_bot(team, exclude_group_id)
    if !bestGroupEid
      groupId = INVALID_GROUP_ID_INT64
      player_group__memberIndex = 0
      return
    query(bestGroupEid) <| $ [es] (player_group__id : int64; var player_group__members : ecs::UInt64List&)
      groupId = player_group__id
      player_group__memberIndex = length(player_group__members)
      player_group__members |> push(INVALID_USER_ID)

def redefine_group_for_bot_member(group_id; member_index)
  find_query() <| $ [es(REQUIRE=playerIsBot)] (eid : EntityId; groupId : int64; player_group__memberIndex : int)
    if groupId == group_id && player_group__memberIndex == member_index
      define_bot_in_group(eid, groupId)
      return true
    return false