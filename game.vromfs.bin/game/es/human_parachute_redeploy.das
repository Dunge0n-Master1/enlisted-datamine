require ecs
require app
require math.base
require game.es.battle_area_common
require common_shooter.es.human.human_parachute_common

[es(tag=server, no_order, REQUIRE_NOT=deadEntity, REQUIRE=(hasParachute, parachuteDeployed))]
def human_parachute_try_queue_redeploy_in_air(info : UpdateStageInfoAct;
                                              transform : float3x4;
                                              team : int;
                                              human_net_phys__velocity : float3;
                                              redeploy__insideAreaTag : string;
                                              human_parachute_redeploy__redeployDelay : float;
                                              human_parachute_redeploy__altitude : float;
                                              human_parachute_redeploy__maxVelocity : float;
                                              human_parachute_redeploy__shouldRedeployCheckInterval : float;
                                              var redeploy__delay : float&;
                                              var redeploy__atTime : float&;
                                              var human_parachute_redeploy__shouldRedeployCheckNextAt : float&)
  if info.curTime < human_parachute_redeploy__shouldRedeployCheckNextAt || redeploy__atTime > 0.0
    return
  human_parachute_redeploy__shouldRedeployCheckNextAt = info.curTime + human_parachute_redeploy__shouldRedeployCheckInterval

  if get_parachute_altitude(transform[3]) > human_parachute_redeploy__altitude || length_sq(human_net_phys__velocity) > square(human_parachute_redeploy__maxVelocity)
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    redeploy__atTime = info.curTime + human_parachute_redeploy__redeployDelay
    redeploy__delay = human_parachute_redeploy__redeployDelay


[es(tag=server, on_disappear, REQUIRE_NOT=deadEntity, REQUIRE=parachuteDeployed)]
def human_parachute_try_queue_redeploy_on_land(evt : Event;
                                               transform : float3x4;
                                               team : int;
                                               redeploy__insideAreaTag : string;
                                               human_parachute_redeploy__redeployDelay : float;
                                               var redeploy__delay : float&;
                                               var redeploy__atTime : float&)
  // dont redeploy if we are already going to
  if redeploy__atTime > 0.0
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    redeploy__atTime = get_sync_time() + human_parachute_redeploy__redeployDelay
    redeploy__delay = human_parachute_redeploy__redeployDelay
