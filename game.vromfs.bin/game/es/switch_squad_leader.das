require ecs
require enlisted.events_enlisted
require game.es.player_events

def find_next_member(members : EidList; leader_eid : EntityId)
  let curMemberIdx = get_int(leader_eid, "squad_member__memberIdx") ?? -1
  var foundEid = INVALID_ENTITY_ID
  var foundPriority = 0
  var foundUndowned = false

  for memberEid in members
    if memberEid == leader_eid
      continue
    query(memberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                        isDowned : bool;
                                                        squad_member__memberIdx : int;
                                                        squad_member__canBeLeader : bool)
      if !squad_member__canBeLeader || (isDowned && foundUndowned)
        return
      let priority = ((squad_member__memberIdx - curMemberIdx + 10000) % 10000)
      if !foundEid || priority < foundPriority || (!isDowned && !foundUndowned)
        foundEid = eid
        foundPriority = priority
        foundUndowned = !isDowned

  return foundEid

def is_valid_squad_member(eid, squad_eid)
  var isValid = false
  query(eid) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__canBeLeader : bool; squad_member__squad : EntityId)
    isValid = squad_member__canBeLeader && squad_member__squad == squad_eid
  return isValid

[es(tag=server)]
def switch_squad_leader_es(evt : CmdSwitchSquadLeader;
                           eid : EntityId;
                           squad__allMembers : EidList;
                           squad__ownerPlayer : EntityId;
                           squad__canChangeMember : bool = true;
                           var squad__leader : EntityId&)
  if !squad__canChangeMember
    return

  var switchToMemberEid = evt.eid
  let curLeaderEid = squad__leader

  if !switchToMemberEid
    switchToMemberEid = find_next_member(squad__allMembers, curLeaderEid)
  elif !is_valid_squad_member(switchToMemberEid, eid)
    switchToMemberEid = INVALID_ENTITY_ID

  if !switchToMemberEid
    return

  squad__leader = switchToMemberEid

  query(squad__ownerPlayer) <| $ [es] (disconnected : bool)
    if !disconnected
      sendEvent(squad__ownerPlayer, [[CmdPossessEntity possessedEid=squad__leader]])

[es(tag=server)]
def squad_request_change_leader_es(evt : RequestSquadChangeLeader; eid : EntityId)
  sendEvent(eid, [[CmdSwitchSquadLeader eid=evt.eid]])