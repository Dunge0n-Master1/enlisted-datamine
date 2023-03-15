require ecs
require ecs.common
require ecs.extra_set
require game.es.player_events
require matching
require game.utils.team
require enlisted.game.es.player_group_common

def find_player_index_in_group(members; uid)
  for i in iter_range(members)
    if members[i] == uid
      return i
  return -1

[es(tag=server, REQUIRE=player, after=player_events_es)]
def group_player_connected(evt : EventOnPlayerConnected;
                           userid : uint64;
                           groupId : int64;
                           team = TEAM_UNASSIGNED;
                           var player_group__memberIndex : int&)
  let found = ecs::find_query() <| $ [es] (player_group__id : int64;
                                           player_group__maxBotPlayers : int;
                                           var player_group__members : ecs::UInt64List&)
    if player_group__id != groupId
      return false

    player_group__memberIndex = player_group__members |> find_player_index_in_group(userid)

    let playerGroupMembersCount = length(player_group__members)

    if player_group__memberIndex == -1
      let botIndex = player_group__members |> find_player_index_in_group(INVALID_USER_ID)
      if playerGroupMembersCount < player_group__maxBotPlayers || botIndex < 0
        player_group__memberIndex = playerGroupMembersCount
        player_group__members |> push(userid)
      else
        redefine_group_for_bot_member(groupId, botIndex)
        player_group__memberIndex = botIndex
        player_group__members[botIndex] = userid
    return true
  if found
    return

  player_group__memberIndex = 0
  createEntitySync("player_group") <| $(var init)
    init |> set("player_group__id", groupId)
    init |> set("player_group__members", [{auto userid}])
    init |> set("player_group__wishTeam", team)