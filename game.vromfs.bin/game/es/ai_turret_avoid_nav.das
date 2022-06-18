require ecs
require app
require ecs.common
require game.es.events
require game.es.ai.walker_common
require game.utils.team
require Gun
require DagorMath
require DagorConsole
require EnlistedWalkerai
require Dacoll

def get_area_name(turret_avoid_nav__areaId : int)
  return "turret{turret_avoid_nav__areaId}"

[es(tag=server, on_appear, REQUIRE=(isTurret, aiAvoidTurret))]
def turret_avoid_nav_create_es(evt : Event;
                               eid : EntityId)
  var enable = true
  ecs::query() <| $ [es] (turret_avoid_debug__mode : int)
    if turret_avoid_debug__mode == 1
      enable = true
    elif turret_avoid_debug__mode == 2
      enable = false
  if enable
    ecs::query(eid) <| $ [es(REQUIRE_NOT=turret_avoid_nav)] ()
      addSubTemplate(eid, "turret_avoid_nav")

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=(isTurret, aiAvoidTurret))]
def turret_avoid_nav_destroy_es(evt : Event;
                                eid : EntityId)
  removeSubTemplate(eid, "turret_avoid_nav")

[es(tag=server, on_appear, REQUIRE=turret_avoid_nav)]
def turret_avoid_nav_created_es(evt : Event;
                                var turret_avoid_nav__areaId : int&)
  turret_avoid_nav__areaId = walker_agent_nav_allocAreaId()

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=turret_avoid_nav)]
def turret_avoid_nav_destroyed_es(evt : Event;
                                  eid : EntityId;
                                  turret_avoid_nav__areaId : int)
  removeSubTemplate(eid, "base_cover_updater")
  ecs::query() <| $ [es] (var walker_agent : EntityAgent; var agentDangerAreas : ecs::Object)
    let areaName = get_area_name(turret_avoid_nav__areaId)
    walker_agent_nav_areaRemove(walker_agent, turret_avoid_nav__areaId)
    erase(agentDangerAreas, areaName)

[es(tag=server, REQUIRE=turret_avoid_nav, after=turret_avoid_nav_created_es)]
def turret_avoid_nav_update_es(info : ecs::UpdateStageInfoAct;
                               eid : EntityId;
                               turret__owner : EntityId;
                               gun : Gun;
                               gun__owner : EntityId;
                               turret_avoid_nav__areaId : int;
                               turret_avoid_nav__areaPosThreshold : float;
                               turret_avoid_nav__areaAngCosThreshold : float;
                               turret_avoid_nav__forwardDist : float2;
                               turret_avoid_nav__sideDist : float2;
                               turret_avoid_nav__weight : float2;
                               turret_avoid_nav__updateDelta : float;
                               var turret_avoid_nav__lastUpdateTime : float&)
  if (info.curTime < turret_avoid_nav__lastUpdateTime + turret_avoid_nav__updateDelta)
    return
  turret_avoid_nav__lastUpdateTime = info.curTime
  var turretTeam = TEAM_UNASSIGNED
  ecs::query(turret__owner) <| $ [es] (team : int)
    turretTeam = team
  var turretIsDangerous = false
  ecs::query(gun__owner) <| $ [es] (isAlive : bool)
    turretIsDangerous = isAlive
  if turretIsDangerous
    ecs::query(eid) <| $ [es(REQUIRE_NOT=humanVisibleCoversMap)] ()
      addSubTemplate(eid, "base_cover_updater")
  else
    ecs::query(eid) <| $ [es(REQUIRE=humanVisibleCoversMap)] ()
      removeSubTemplate(eid, "base_cover_updater")

  var maxLen = -1.0f
  ecs::query() <| $ [es] (var walker_agent : EntityAgent;
                          var agentDangerAreas : ecs::Object;
                          isAlive : bool;
                          isDowned : bool;
                          isInVehicle : bool;
                          team : int)
    let areaName = get_area_name(turret_avoid_nav__areaId)
    if isAlive && !isDowned && !isInVehicle && turretIsDangerous && !is_teams_friendly(team, turretTeam)
      var tm = gun.gunTm
      if maxLen < 0.0f
        maxLen = 0.0f
        let numSteps = 2
        for i in range(-numSteps, numSteps + 1)
          let absI = int(abs(float(i)))
          let rowEven = (absI % 2) == 0
          for j in range(absI - numSteps, numSteps + 1 - absI)
            let absJ = int(abs(float(j)))
            let colEven = (absJ % 2) == 0
            if rowEven == colEven
              let startPt = tm[3]
              let dir = (tm[0] * turret_avoid_nav__forwardDist.y +
                         tm[2] * turret_avoid_nav__sideDist.x * (float(j) / float(numSteps)) +
                         tm[1] * turret_avoid_nav__sideDist.y * (float(i) / float(numSteps)))
              var len = length(dir)
              let dirN = dir / len
              var norm : float3
              traceray_normalized(startPt, dirN, len, norm)
              maxLen = max(maxLen, dot(dir, tm[0]))

      let oobb = BBox3(float3(-turret_avoid_nav__sideDist.x, -turret_avoid_nav__sideDist.y, turret_avoid_nav__forwardDist.x),
        float3(turret_avoid_nav__sideDist.x, turret_avoid_nav__sideDist.y, maxLen))
      let tmp = tm[0]
      tm[0] = tm[2]
      tm[2] = tmp
      walker_agent_nav_areaUpdateBox(walker_agent, turret_avoid_nav__areaId, tm, oobb,
                                     turret_avoid_nav__weight.x, turret_avoid_nav__weight.y, false,
                                     turret_avoid_nav__areaPosThreshold, turret_avoid_nav__areaAngCosThreshold)
      danger_area_update(agentDangerAreas, areaName, tm, oobb)
    else
      walker_agent_nav_areaRemove(walker_agent, turret_avoid_nav__areaId)
      erase(agentDangerAreas, areaName)
