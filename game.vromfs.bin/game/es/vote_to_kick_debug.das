options no_aot
require ecs
require DngNet
require player
require game.utils.team
require strings
require DagorConsole
require enlisted.events_enlisted
require game.es.net_console_macro

[console_cmd(name="vote_kick.voteFor")]
def vote_kick_vote_for_cmd(playerName : string; voteYes : bool)
  let find = find_query() <| $ [es(REQUIRE=player)] (eid : EntityId; name : string)
    if replace(name, " ", "") == playerName
      send_net_event(get_local_player_eid(), [[CmdVoteToKick voteYes=voteYes, accused=eid]])
      return true
    return false
  if !find
    console_print("Player with name: {playerName} not exist!")

[console_cmd(name="vote_kick.kickFirstPlayer")]
def kick_first_player_cmd()
  let playerTeam = get_local_player_team()
  find_query() <| $ [es(REQUIRE=player)] (eid : EntityId; disconnected : bool; is_local : bool; team : int)
    if is_local || disconnected || playerTeam != team
      return false
    send_net_event(get_local_player_eid(), [[CmdVoteToKick voteYes=true, accused=eid]])
    return true

[net_console_cmd(name="vote_kick.enabled")]
def vote_kick_enable_cmd(enable : bool = true)
  let voteKickEid = getSingletonEntity("vote_to_kick")
  if !enable
    destroyEntity(voteKickEid)
    return
  if enable && !voteKickEid
    createEntity("vote_to_kick")
