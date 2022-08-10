require ecs
require game.utils.team


def is_player_squad_alive(player_eid)
  return find_query() <| $ [es] (squad__ownerPlayer : EntityId; squad__isAlive : bool)
    return squad__ownerPlayer == player_eid && squad__isAlive

typedef
  Set = table < string; bool >

struct Capzone
  group : string
  reward : float
  next : string


def get_group_links(capzones : array<Capzone>)
  var links : table<string; Set>
  for capzone in capzones
    if capzone.group != ""
      if !key_exists(links, capzone.group)
        var next : Set
        links[capzone.group] <- next
      if capzone.next != ""
        links[capzone.group][capzone.next] = true
  return <- links


def get_all_next_groups(capzones : array<Capzone>; start_groups : Set)
  let links <- get_group_links(capzones)
  var visited : Set
  var open := start_groups

  for _i in range(length(links))
    for group in keys(open)
      visited[group] = true
    var nextOpen : Set
    for group in keys(open)
      let nextGroups = find(links, group)
      if nextGroups != null
        for nextGroup in keys(*nextGroups)
          if !key_exists(visited, nextGroup)
            nextOpen[nextGroup] = true
    open <- nextOpen
    if length(open) == 0
      break

  return <- visited


def can_team_increase_score(team : int) : bool
  var capzones : array<Capzone>
  var groupsAfterCurrent : Set
  var activeCapzonesReward = 0.0
  query() <| $ [es(REQUIRE=capzone)] (active : bool;
                                      groupName : string;
                                      capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                                      capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                                      capzone__capReward : float = 0.0;
                                      capzone__capRewardTeam1 : float = -1.0;
                                      capzone__capRewardTeam2 : float = -1.0;
                                      capzone__activateAfterCap : string = "")
    let capReward = (team == 1 && capzone__capRewardTeam1 >= 0. ? capzone__capRewardTeam1
                   : team == 2 && capzone__capRewardTeam2 >= 0. ? capzone__capRewardTeam2
                   : capzone__capReward)
    if (team == capzone__onlyTeamCanCapture || capzone__mustBeCapturedByTeam == team)
      capzones |> emplace([[Capzone group=groupName, reward=capReward, next=capzone__activateAfterCap]])
      if active
        activeCapzonesReward += capReward
        if capzone__activateAfterCap != ""
          groupsAfterCurrent[capzone__activateAfterCap] = true
  if length(groupsAfterCurrent) > 0 && activeCapzonesReward > 0.0
    return true
  let nextGroups <- get_all_next_groups(capzones, groupsAfterCurrent)
  let nonFinalCapzoneWithRewardAfterCurrentIndex = find_index_if(capzones) <| $(capzone)
    return capzone.next != "" && capzone.reward > 0.0 && key_exists(nextGroups, capzone.group)
  return nonFinalCapzoneWithRewardAfterCurrentIndex >= 0


[es(tag=server, track=squad__isAlive)]
def player_game_finished_last_squad_died(evt : Event; squad__ownerPlayer : EntityId; squad__isAlive : bool)
  if !squad__isAlive
    query(squad__ownerPlayer) <| $ [es] (squads__squadsCanSpawn : bool; team : int; disconnected : bool; var scoring_player__isGameFinished : bool&)
      if disconnected
        return
      if !squads__squadsCanSpawn
        scoring_player__isGameFinished = true
        return
      let noMoreTeamSpawns = find_query() <| $ [es] (team__id : int; team__noMoreSpawns : bool)
        return team__id == team && team__noMoreSpawns
      if noMoreTeamSpawns
        scoring_player__isGameFinished = true

[es(tag=server, track=team__squadsCanSpawn)]
def player_game_finished_track_team_can_spawn(evt : Event; team__id : int; team__squadsCanSpawn : bool; var team__noMoreSpawns : bool&)
  team__noMoreSpawns = !team__squadsCanSpawn && !can_team_increase_score(team__id)
  if team__noMoreSpawns
    query() <| $ [es(REQUIRE=player)] (eid : EntityId; team : int; disconnected : bool; var scoring_player__isGameFinished : bool&)
      if team == team__id && !disconnected && !is_player_squad_alive(eid)
        scoring_player__isGameFinished = true

[es(tag=server, on_event=EventTeamRoundResult, REQUIRE=player, before=send_userstats_es)]
def player_game_finished_on_battle_result(evt : Event; disconnected : bool; var scoring_player__isGameFinished : bool&)
  scoring_player__isGameFinished ||= !disconnected