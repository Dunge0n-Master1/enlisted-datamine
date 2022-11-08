require ecs
require DagorSystem
require game.utils.team
require game.es.battle_area_common
require enlisted.game.es.teleport_common
require enlisted.events_enlisted


[es(tag=server, after=hitpoints_es, REQUIRE_NOT=deadEntity, REQUIRE=human__redeployable)]
def try_redeploy_soldier(info : UpdateStageInfoAct;
                         eid : EntityId;
                         transform : float3x4;
                         redeploy__insideAreaTag : string;
                         var redeploy__atTime : float&;
                         team : int = TEAM_UNASSIGNED;
                         isDowned : bool = false)
  if redeploy__atTime < 0.0 || info.curTime < redeploy__atTime
    return
  redeploy__atTime = -1.0

  if isDowned
    return

  let noRedeployAreasResult = find_active_battle_areas(transform[3], team, redeploy__insideAreaTag) <| $ [unused_argument(area_eid)] (area_eid) => true
  if noRedeployAreasResult != FindActiveBattleAreasRes found
    let playerTeam = team
    let playerPos = transform[3]

    var respbaseFound = false
    var closestRespbasePos = float3(0.0)
    query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, vehicleRespbase, playerRespawnBase, customRespawnBase))] (active : bool; transform : float3x4; team : int)
      if !active || playerTeam != team
        return
      if !respbaseFound || length_sq(playerPos - transform[3]) < length_sq(playerPos - closestRespbasePos)
        closestRespbasePos = transform[3]
        respbaseFound = true

    if !respbaseFound
      logwarn("No respawn base was found for {eid} in team {team} for redeploy!")
      return

    teleport_or_request(eid, closestRespbasePos)
    sendEvent(eid, [[EventEntityRedeployed]])
