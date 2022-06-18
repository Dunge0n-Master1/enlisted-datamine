require enlisted.game.es.player_group_common
require ecs
require ecs.common
require matching

[es(tag=server, REQUIRE=(playerIsBot, player), on_appear)]
def group_bot_player_connected(evt : Event;
                               groupId : int64;
                               eid : EntityId)
  if groupId != INVALID_GROUP_ID_INT64 || !is_bot_auto_squad()
    return
  define_bot_in_group(eid)

[es(tag=server, on_appear)]
def fill_new_group_by_bot_players(evt : Event;
                                  player_group__id : int64;
                                  player_group__maxBotPlayers : int;
                                  player_group__wishTeam : int;
                                  var player_group__members : ecs::UInt64List&)
  if player_group__id == INVALID_GROUP_ID_INT64 || !is_bot_auto_squad()
    return
  let membersInGroup = length(player_group__members)
  var requireBotsPlayers = player_group__maxBotPlayers - membersInGroup
  find_query() <| $ [es(REQUIRE=playerIsBot)] (team : int;
                                               var groupId : int64&;
                                               var player_group__memberIndex : int&)
    if groupId == INVALID_GROUP_ID_INT64 && team == player_group__wishTeam
      groupId = player_group__id
      player_group__memberIndex = length(player_group__members)
      player_group__members |> push(INVALID_USER_ID)
      requireBotsPlayers--
    return requireBotsPlayers <= 0