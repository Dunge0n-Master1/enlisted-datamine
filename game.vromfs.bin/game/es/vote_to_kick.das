require ecs
require ecs.extra_set
require app
require EnlistedNet
require player
require game.utils.net_utils
require ecs.common
require EnlistedDm
require game.utils.team
require game.es.events
require enlisted.events_enlisted
require danetlibs.native_dasevents.main.native_events

def get_player_count_in_team(accused_team)
  var totalPlayerCount = 0
  query() <| $ [es(REQUIRE=player, REQUIRE_NOT=playerIsBot)] (team : int; disconnected : bool)
    if team == accused_team && !disconnected
      totalPlayerCount++
  return totalPlayerCount

def kill_disconnected_squad_member(possessed : EntityId)
  query(possessed) <| $ [es] (squad_member__squad : EntityId)
    query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
      for member in squad__allMembers
        sendEvent(member, [[CmdKill offender=member, damageType=uint16(int(DamageType DM_DISCONNECTED)), gunPropsId=-1, shellId=-1]])

[es(tag=server, REQUIRE=player)]
def vote_to_kick_es(evt : CmdVoteToKick; eid : EntityId; team aka player_team : int)
  query() <| $ [es] (vote_to_kick__kickVotingTemplate : string; vote_to_kick__time : float)
    let accused = evt.accused
    var canVote = false

    query(accused) <| $ [es] (team : int)
      canVote = player_team == team

    if !canVote
      sendEvent(eid, [[CmdHeroLogEvent event="vote_to_kick_cant_kick_this_player", text="vote_to_kick_cant_kick_this_player"]])
      return

    canVote = !find_query() <| $ [es] (kick_voting__accused : EntityId; kick_voting__voteYes : EidList; kick_voting__voteNo : EidList)
      return kick_voting__accused != accused || has_value(kick_voting__voteYes, eid) || has_value(kick_voting__voteNo, eid)

    if !canVote
      sendEvent(eid, [[CmdHeroLogEvent event="vote_to_kick_already_process", text="vote_to_kick_already_process"]])
      return

    canVote = accused != eid
    query(accused) <| $ [es(REQUIRE_NOT=playerIsBot)] (player__roomOwner : bool; vote_to_kick__kicked : bool)
      canVote &&= !vote_to_kick__kicked && !player__roomOwner

    if !canVote
      return

    let find = find_query() <| $ [es] (kick_voting__accused : EntityId;
                                       var kick_voting__voteYes : EidList&;
                                       var kick_voting__voteNo : EidList&)
      if kick_voting__accused != accused
        return false

      (evt.voteYes ? kick_voting__voteYes : kick_voting__voteNo) |> push(eid)
      return true

    if find
      return

    createEntity(vote_to_kick__kickVotingTemplate) <| $(init)
      init |> set("kick_voting__accused", accused)
      init |> set("kick_voting__timer", get_sync_time() + vote_to_kick__time)
      let voteComp = evt.voteYes ? "kick_voting__voteYes" : "kick_voting__voteNo"
      init |> set(voteComp, [{auto eid}])

[es(tag=server, no_order)]
def vote_to_kick_timer_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                          kick_voting__timer : float;
                          kick_voting__voteYes : EidList;
                          kick_voting__voteNo : EidList;
                          kick_voting__accused : EntityId)
  if kick_voting__timer > info.curTime
    return

  let voteDiff = length(kick_voting__voteYes) - length(kick_voting__voteNo)
  var kicked = false

  query(kick_voting__accused) <| $ [es] (connid : int;
                                         userid : uint64;
                                         team : int;
                                         var disconnected : bool&;
                                         var possessed : EntityId&;
                                         var clientNetFlags : int&;
                                         var vote_to_kick__kicked : bool&)

    let totalPlayerCount = get_player_count_in_team(team)
    print("[VOTE]: diff={voteDiff}; total player={totalPlayerCount}")
    if voteDiff <= totalPlayerCount / 2
      destroyEntity(eid)
      return

    var conn = get_client_connection(connid)
    if conn == null
      disconnected = true
    else
      net_disconnect(*conn, DisconnectionCause DC_KICK_VOTE)

    clientNetFlags |= int(ClientNetFlags CNF_RECONNECT_FORBIDDEN)
    vote_to_kick__kicked = true
    kicked = true
    kill_disconnected_squad_member(possessed)
    possessed = INVALID_ENTITY_ID
    print("[VOTE]: Kick player {eid} with userId {int(userid)} votes {voteDiff}")

  send_net_event(kick_voting__accused, [[VoteKickResult kicked=kicked]])
  destroyEntity(eid)