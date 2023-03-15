require ecs
require EnlistedDm
require game.events_game
require game.utils.team
require EnlistedNet

[es(tag=server, REQUIRE=damage_model, track=isAlive)]
def damage_model_death_es(evt : Event;
                          eid : EntityId;
                          lastOffender : EntityId;
                          team : int;
                          isAlive : bool;
                          last_offender__shellId : int = -1;
                          last_offender__gunPropsId : int = -1)
  if isAlive
    return

  var offenderPossessedByPlr = INVALID_ENTITY_ID
  var offenderSquad = INVALID_ENTITY_ID
  var offenderTeam = TEAM_UNASSIGNED

  query(lastOffender) <| $ [es] (squad_member__squad : EntityId; possessedByPlr : EntityId; team : int)
    offenderSquad = squad_member__squad
    offenderPossessedByPlr = possessedByPlr
    offenderTeam = team

  let damageType = int(DamageType DM_EXPLOSION)
  let gunPropsId = last_offender__gunPropsId
  let shellId = last_offender__shellId
  let collNodeId = -1
  send_net_event(eid, [[EventEntityDied victim=eid, offender=lastOffender,
    damageType=damageType, gunPropsId=gunPropsId, shellId=shellId, collNodeId=collNodeId, victimTeam=team, offenderTeam=offenderTeam]])
  broadcast_net_event([[EventAnyEntityDied victim=eid, offender=lastOffender, offenderPlayer=offenderPossessedByPlr, victimPlayer=INVALID_ENTITY_ID,
                                           damageType=damageType, gunPropsId=gunPropsId, shellId=shellId,
                                           collNodeId=collNodeId, victimTeam=team, offenderTeam=offenderTeam]])
