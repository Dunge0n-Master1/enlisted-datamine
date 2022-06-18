require ecs
require app
require DagorSystem
require Dacoll
require math.base
require game.utils.team
require game.es.battle_area_common
require enlisted.game.es.enl_teleport_common
require common_shooter.es.human.human_parachute_common


[es(tag=server, after=hitpoints_es, REQUIRE_NOT=deadEntity, REQUIRE=hasParachute)]
def human_parachute_try_redeploy(info : UpdateStageInfoAct;
                                 eid : EntityId;
                                 transform : float3x4;
                                 squad_member__squad : EntityId;
                                 human_parachute_redeploy__insideAreaTag : string;
                                 var human_parachute_redeploy__redeployAtTime : float&;
                                 team : int = TEAM_UNASSIGNED;
                                 isDowned : bool = false)
  if human_parachute_redeploy__redeployAtTime < 0.0 || info.curTime < human_parachute_redeploy__redeployAtTime
    return
  human_parachute_redeploy__redeployAtTime = -1.0

  if isDowned
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, human_parachute_redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    let playerTeam = team
    let playerPos = transform[3]

    var respbaseFound = false
    var closestRespbasePos = float3(0.0)
    ecs::query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, vehicleRespbase, playerRespawnBase, customRespawnBase))] (active : bool; transform : float3x4; team : int)
      if !active || playerTeam != team
        return
      if !respbaseFound || length_sq(playerPos - transform[3]) < length_sq(playerPos - closestRespbasePos)
        closestRespbasePos = transform[3]
        respbaseFound = true

    if !respbaseFound
      logwarn("No respawn base was found for {eid} in team {team} after landing on a parachute!")
      return

    teleport_squad_to_pos(squad_member__squad, closestRespbasePos)


[es(tag=server, no_order, REQUIRE_NOT=deadEntity, REQUIRE=(hasParachute, parachuteDeployed))]
def human_parachute_try_queue_redeploy_in_air(info : UpdateStageInfoAct;
                                              transform : float3x4;
                                              team : int;
                                              human_net_phys__velocity : float3;
                                              human_parachute_redeploy__insideAreaTag : string;
                                              human_parachute_redeploy__redeployDelay : float;
                                              human_parachute_redeploy__altitude : float;
                                              human_parachute_redeploy__maxVelocity : float;
                                              human_parachute_redeploy__shouldRedeployCheckInterval : float;
                                              var human_parachute_redeploy__redeployAtTime : float&;
                                              var human_parachute_redeploy__shouldRedeployCheckNextAt : float&)
  if info.curTime < human_parachute_redeploy__shouldRedeployCheckNextAt || human_parachute_redeploy__redeployAtTime > 0.0
    return
  human_parachute_redeploy__shouldRedeployCheckNextAt = info.curTime + human_parachute_redeploy__shouldRedeployCheckInterval

  if get_parachute_altitude(transform[3]) > human_parachute_redeploy__altitude || length_sq(human_net_phys__velocity) > square(human_parachute_redeploy__maxVelocity)
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, human_parachute_redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    human_parachute_redeploy__redeployAtTime = info.curTime + human_parachute_redeploy__redeployDelay


[es(tag=server, on_disappear, REQUIRE_NOT=deadEntity, REQUIRE=parachuteDeployed)]
def human_parachute_try_queue_redeploy_on_land(evt : Event;
                                               transform : float3x4;
                                               team : int;
                                               human_parachute_redeploy__insideAreaTag : string;
                                               human_parachute_redeploy__redeployDelay : float;
                                               var human_parachute_redeploy__redeployAtTime : float&)
  // dont redeploy if we are already going to
  if human_parachute_redeploy__redeployAtTime > 0.0
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, human_parachute_redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    human_parachute_redeploy__redeployAtTime = get_sync_time() + human_parachute_redeploy__redeployDelay