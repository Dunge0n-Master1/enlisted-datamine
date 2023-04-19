require ecs
require ecs.safe
require game.es.awards_common
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require DngDm
require dm

def is_vehicle_damaged(meta_parts_state : MetaPartsState; damage_model : DamageModel)
  return ((find_index_if(each(damage_model.dmData.parts)) <| $(part) => uint(part.relHpFixed) < uint(MAX_REL_HP_FIXED)) >= 0
       || (find_index_if(each(meta_parts_state.state)) <| $(part) => uint(part.hp) < uint(MAX_REL_HP_FIXED)) >= 0)

[es(tag=server, REQUIRE=airplane, before=vehicle_seats_enter_exit_kick_server_es)]
def paratrooper_award_condition_damaged_plane(evt : CmdKickFromVehicle;
                                              ownedBySquad : EntityId;
                                              meta_parts_state : MetaPartsState;
                                              damage_model : DamageModel)
  if is_vehicle_damaged(meta_parts_state, damage_model)
    query(evt.eid) <| $ [es] (squad_member__squad : EntityId; var paratrooper_award__wasInDamagedSquadPlane : bool&)
      if squad_member__squad == ownedBySquad
        paratrooper_award__wasInDamagedSquadPlane = true

[es(tag=server, REQUIRE=hasParachute, track=human_parachute__isDeployed)]
def paratrooper_award_condition_parachute(evt : Event;
                                          human_parachute__isDeployed : bool;
                                          paratrooper_award__wasInDamagedSquadPlane : bool;
                                          var paratrooper_award__isActive : bool&)
  if !human_parachute__isDeployed && paratrooper_award__wasInDamagedSquadPlane
    paratrooper_award__isActive = true

[es(tag=server)]
def paratrooper_award_count_kills(evt : OnScoringKillBySquadMember;
                                  eid aka player_eid : EntityId;
                                  soldierStats : Object;
                                  var scoring_player__bestOneSodierLifeParatrooperKills : int&)
  query(evt.offender) <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=hasParachute)] (guid : string;
                                                                               paratrooper_award__isActive : bool;
                                                                               var paratrooper_award__kills : int&)
    if !paratrooper_award__isActive
      return
    paratrooper_award__kills += 1
    let prevBest = (soldierStats[guid] ?as Object)?.bestOneLifeParatrooperKills ?? 0
    if paratrooper_award__kills > prevBest
      send_award_stat(player_eid, guid, "bestOneLifeParatrooperKills", float(paratrooper_award__kills), /*override*/ true)
    scoring_player__bestOneSodierLifeParatrooperKills = max(scoring_player__bestOneSodierLifeParatrooperKills, paratrooper_award__kills)
