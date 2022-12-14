require ecs
require game.es.events
require game.utils.team
require DagorRandom
require game.es.vehicle.vehicle_events
require game.events_game
require game.utils.team
require EnlistedHuman


[es(REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def downed_soldier_finisher_es(evt : Event;
                               eid : EntityId;
                               var hitpoints__hp : float&;
                               hitpoints__deathHpThreshold : float;
                               team, total_kits__selfRevive : int;
                               human_anim__vehicleSelected : EntityId;
                               hitpoints__canBeDownedInVehicle : bool = false;
                               hitpoints__canBeRevivedByTeammates : bool = false;
                               hitpoints__alwaysAllowRevive : bool = false)
  if human_anim__vehicleSelected != INVALID_ENTITY_ID
    if hitpoints__canBeDownedInVehicle
      sendEvent(human_anim__vehicleSelected, [[CmdKickFromVehicle eid=eid]])
    else
      hitpoints__hp = hitpoints__deathHpThreshold
  if hitpoints__alwaysAllowRevive || total_kits__selfRevive > 0 || (hitpoints__canBeRevivedByTeammates && have_active_teammates(eid, team))
    return
  hitpoints__hp = hitpoints__deathHpThreshold

[es(REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def downed_chance_soldier_finisher_es(evt : Event;
                                      var hitpoints__hp : float&;
                                      hitpoints__deathHpThreshold : float;
                                      hitpoints__downedKillChanceMult : float;
                                      hitpoints__downedKillChanceBase : float)
  let hpProportion = hitpoints__hp / hitpoints__deathHpThreshold
  let dice = gfrnd()
  let chance = hitpoints__downedKillChanceBase + hpProportion * hitpoints__downedKillChanceMult
  if dice < chance
    hitpoints__hp = hitpoints__deathHpThreshold


def lose_team_finisher(eid, victim : EntityId; team : int;
                       isAlive, isDowned : bool;
                       hitpoints__canBeRevivedByTeammates : bool;
                       var hitpoints__hp : float&;
                       total_kits__selfRevive : int;
                       hitpoints__deathHpThreshold : float)
  if eid == victim || victim == INVALID_ENTITY_ID || total_kits__selfRevive > 0
    return
  if isAlive && isDowned && is_teams_friendly(get_int(victim, "team") ?? TEAM_UNASSIGNED, team) && hitpoints__canBeRevivedByTeammates
    if !have_active_teammates(eid, team)
      hitpoints__hp = hitpoints__deathHpThreshold


[es(REQUIRE=human, tag=server)]
def lose_team_finisher_downed_es(evt : EventAnyEntityDowned;
                                 eid : EntityId; team : int;
                                 isAlive, isDowned : bool;
                                 hitpoints__canBeRevivedByTeammates : bool;
                                 var hitpoints__hp : float&;
                                 total_kits__selfRevive : int = 0;
                                 hitpoints__deathHpThreshold : float = 0.0)
  lose_team_finisher(eid, evt.victim, team, isAlive, isDowned, hitpoints__canBeRevivedByTeammates, hitpoints__hp,
                     total_kits__selfRevive, hitpoints__deathHpThreshold)


[es(REQUIRE=human, tag=server)]
def lose_team_finisher_died_es(evt : EventAnyEntityDied;
                               eid : EntityId; team : int;
                               isAlive, isDowned : bool;
                               hitpoints__canBeRevivedByTeammates : bool;
                               var hitpoints__hp : float&;
                               total_kits__selfRevive : int = 0;
                               hitpoints__deathHpThreshold : float = 0.0)
  lose_team_finisher(eid, evt.victim, team, isAlive, isDowned, hitpoints__canBeRevivedByTeammates, hitpoints__hp,
                     total_kits__selfRevive, hitpoints__deathHpThreshold)


[es(REQUIRE=human, tag=server, track=burning__isBurning)]
def burning_finisher_es(evt : Event;
                        isAlive, isDowned, burning__isBurning : bool;
                        var hitpoints__hp : float&;
                        hitpoints__deathHpThreshold : float = 0.0;
                        hitpoints__downedKillWhenBurning = false)
  if isAlive && isDowned && burning__isBurning && hitpoints__downedKillWhenBurning
    hitpoints__hp = hitpoints__deathHpThreshold

[es(REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def burning_finisher_before_downed(evt : Event;
                                   isAlive, burning__isBurning : bool;
                                   var hitpoints__hp : float&;
                                   hitpoints__deathHpThreshold : float = 0.0;
                                   hitpoints__downedKillWhenBurning = false)
  if isAlive && burning__isBurning && hitpoints__downedKillWhenBurning
    hitpoints__hp = hitpoints__deathHpThreshold


[es(REQUIRE=human, tag=server, on_event=EventEntityDowned)]
def set_downed_minDmgSpd_es(evt : Event; var human_coll_damage__minDmgSpd : float&;
                            var human_coll_damage__lastMinDmgSpd : float&;
                            human_coll_damage__downedMinDmgSpd : float)
  human_coll_damage__lastMinDmgSpd = human_coll_damage__minDmgSpd
  human_coll_damage__minDmgSpd = human_coll_damage__downedMinDmgSpd

[es(REQUIRE=human, tag=server, on_event=EventEntityRevived)]
def unset_downed_minDmgSpd_es(evt : Event; var human_coll_damage__minDmgSpd : float&;
                              human_coll_damage__lastMinDmgSpd : float;
                              human_coll_damage__downedMinDmgSpd : float)
  if human_coll_damage__minDmgSpd == human_coll_damage__downedMinDmgSpd
    human_coll_damage__minDmgSpd = human_coll_damage__lastMinDmgSpd

[es(REQUIRE=human, tag=server, track=isOutsideBattleArea)]
def outside_battle_area_finisher_es(evt : Event;
                                    isAlive, isDowned, isOutsideBattleArea : bool;
                                    var hitpoints__hp : float&;
                                    hitpoints__deathHpThreshold : float = 0.0)
  if isAlive && isDowned && isOutsideBattleArea
    hitpoints__hp = hitpoints__deathHpThreshold

[es(REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def outside_battle_area_finisher_before_downed(evt : Event;
                                               isAlive, isOutsideBattleArea : bool;
                                               var hitpoints__hp : float&;
                                               hitpoints__deathHpThreshold : float = 0.0)
  if isAlive && isOutsideBattleArea
    hitpoints__hp = hitpoints__deathHpThreshold

[es(REQUIRE=human, tag=server, on_event=EventOnDownedThreshold)]
def fall_speed_finisher_before_downed(evt : Event;
                                      isAlive : bool;
                                      human_net_phys : HumanActor;
                                      hitpoints__fatalFallSpeed : float;
                                      var hitpoints__hp : float&;
                                      hitpoints__deathHpThreshold : float = 0.0)
  let spdSummaryDiffY = human_net_phys.phys.currentState.spdSummaryDiff.y
  if isAlive && spdSummaryDiffY > hitpoints__fatalFallSpeed
    hitpoints__hp = hitpoints__deathHpThreshold