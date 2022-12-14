require ecs
require ecs.common
require app
require walkerai
require game.utils.team
require math
require math.base
require DagorRandom
require DagorMath
require Dacoll
require RendInst
require CollRes
require AnimV20
require Grid
require GridCollision
require common_shooter.es.ai.ai_danger_common
require game.es.ai.walker_common
require SmokeOccluder
require EnlistedHuman
require HumanPhys
require DagorMath

struct TargetData
  eid : EntityId
  team : int
  isAlive : bool
  isDowned : bool
  isHidden : bool
  targetPos : float3
  stance : int

def TargetData(eid : EntityId; team : int; target : Target; stance : int)
  return [[TargetData eid = eid,
           team = team,
           isAlive = target.isAlive,
           isDowned = target.isDowned,
           isHidden = target.isHidden,
           targetPos = target.targetPos,
           stance = stance]]

def find_danger(var agent_dangers : AgentDangers; eid : EntityId)
  for i in iter_range(agent_dangers.dangers)
    if agent_dangers.dangers[i].eid == eid
      return i
  return -1

[es(tag=server, no_order)]
def ai_danger_update_alertness(act : UpdateStageInfoAct)
  var targets : table<uint; TargetData>
  query() <| $ [es(REQUIRE_NOT=ai_target__autoGunTarget)] (eid : EntityId; ai_target : Target; team : int;
                                                           human_net_phys : HumanActor const?; vehicle_seats__seatEids : EidList const?)
    var stance = STANCE_STAND
    var targetTeam = team
    if human_net_phys != null
      stance = determinate_stance(human_net_phys.phys.currentState)
    if vehicle_seats__seatEids != null && team == TEAM_UNASSIGNED
      for seatEid in *vehicle_seats__seatEids
        query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
          query(seat__ownerEid) <| $ [es] (team aka passenger_team : int)
            targetTeam = passenger_team
    var targetData = TargetData(eid, targetTeam, ai_target, stance)
    targets[uint(eid)] <- targetData

  query() <| $ [es] (eid : EntityId;
                     isAlive : bool; team : int;
                     beh_tree__enabled : bool = true;
                     isInVehicle : bool = false;
                     var agent_dangers : AgentDangers;
                     agent_dangers__standShootPos : float3;
                     agent_dangers__standShootDir : float3;
                     agent_dangers__maxDangerDist : float;
                     var agent_dangers__nextDangersCheckTime : float&;
                     alertness_calc__distCoef : float2;
                     alertness_calc__inFrustumCoef : float2;
                     alertness_calc__frustumCoef : float3;
                     alertness_calc__frustumOffset : float2;
                     alertness_calc__crouchCoef : float;
                     alertness_calc__crawlCoef : float;
                     alertness_calc__downedCoef : float;
                     alertness_calc__inVehicleCoef : float;
                     agent_dangers__targetAirplanePilots : bool;
                     agent_dangers__checkTimes = float2(0.3, 0.7);
                     agent_dangers__frustumAngle = 40.; agent_dangers__blindDistance = 200.)

    if !isAlive || !beh_tree__enabled
      clear(agent_dangers.dangers)
      return
    if act.curTime < agent_dangers__nextDangersCheckTime
      return

    agent_dangers__nextDangersCheckTime = act.curTime + rnd_float(agent_dangers__checkTimes.x, agent_dangers__checkTimes.y);

    let frustumMinCos = cos(deg_to_rad(agent_dangers__frustumAngle))

    var i = length(agent_dangers.dangers)
    while --i >= 0
      assume danger = agent_dangers.dangers[i]
      if !(targets |> key_exists(uint(danger.eid)))
        agent_dangers.dangers |> erase(i)

    for target in values(targets)
      let dangerIdx = find_danger(agent_dangers, target.eid)
      if !target.isAlive || target.isHidden || is_teams_friendly(team, target.team) || target.eid == eid || target.team == TEAM_UNASSIGNED
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
        continue

      if !agent_dangers__targetAirplanePilots
        var isInAirplane = false
        query(target.eid) <| $ [es] (human_anim__vehicleSelected : EntityId)
          query(human_anim__vehicleSelected) <| $ [es(REQUIRE=airplane)]
            isInAirplane = true

        if isInAirplane
          if dangerIdx >= 0
            erase(agent_dangers.dangers, dangerIdx)
          continue

      let targetDir = target.targetPos - agent_dangers__standShootPos
      let dist = length(targetDir)
      if dist > agent_dangers__blindDistance
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
        continue

      let frustumCos = dot(normalize(targetDir), agent_dangers__standShootDir)
      let inFrustum = frustumCos >= frustumMinCos
      let inVehicleCoef = isInVehicle ? alertness_calc__inVehicleCoef : 1.
      let alertness = calc_target_alertness(dist, inFrustum, frustumCos, target.stance, target.isDowned,
                                            agent_dangers__maxDangerDist, alertness_calc__distCoef,
                                            alertness_calc__inFrustumCoef, alertness_calc__frustumCoef, alertness_calc__frustumOffset,
                                            alertness_calc__crouchCoef, alertness_calc__crawlCoef, alertness_calc__downedCoef,
                                            inVehicleCoef)
      if alertness <= 0.0
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
      else
        if dangerIdx >= 0
          assume danger = agent_dangers.dangers[dangerIdx]
          danger.distance = dist
          danger.alertness = alertness
          if !inFrustum
            danger.inFrustumTime = -1f
          elif danger.inFrustumTime < 0f
            danger.inFrustumTime = act.curTime
        else
          using() <| $(var newDanger : Danger#)
            newDanger.eid = target.eid
            newDanger.inFrustumTime = inFrustum ? act.curTime : -1.
            newDanger.distance = dist
            newDanger.alertness = alertness
            push_clone(agent_dangers.dangers, newDanger)

[es(tag=server, on_appear)]
def ai_danger_update_time_init(evt : Event; eid : EntityId; agent_dangers__initialDangersTraceCheckTime : float = 1.0;
                               var agent_dangers__nextDangersTraceTime : float&)
  agent_dangers__nextDangersTraceTime = get_sync_time() + agent_dangers__initialDangersTraceCheckTime * eid_frnd(eid)

def get_shoot_ray_mat(human_attached_gun__attachedGunEid, human_weap__currentGunEid : EntityId)
  var res = -1
  let gunEid = human_attached_gun__attachedGunEid != INVALID_ENTITY_ID ? human_attached_gun__attachedGunEid : human_weap__currentGunEid
  query(gunEid) <| $ [es] (gun__aimRayMatId : int)
    res = gun__aimRayMatId
  return res

[es(tag=server, after=(ai_danger_update_traceable, ai_target_es, ai_target_transform_es))]
def ai_danger_trace_targets(act : UpdateStageInfoAct; eid : EntityId; isAlive : bool;
                            var agent_dangers : AgentDangers;
                            agent_dangers__standShootPos : float3;
                            beh_tree__enabled : bool = true;
                            var agent_dangers__nextDangersTraceTime : float&;
                            danger_calc__aiCoef : float2;
                            danger_calc__avoidBulletsNearTime : float;
                            danger_calc__lastShootCoef : float2;
                            danger_calc__noiseCoef : float2;
                            danger_calc__lastBulletNearbyCoef : float2;
                            agent_dangers__nextDangersTraceCheckTime : float = 0.1f;
                            var human_stat_tracking__targetTracesCount : int?;
                            agent_dangers__minTraceableRatio : float = 3.7;
                            agent_dangers__retraceTargetsTime : float = 30f;
                            agent_dangers__maxDangerDist : float = 100f;
                            agent_dangers_calc__dangerMeterMult : float = 1f;
                            agent_dangers__hmapTraceOffset : float3 = float3(0., 0., 0.);
                            human_attached_gun__attachedGunEid = INVALID_ENTITY_ID;
                            human_weap__currentGunEid = INVALID_ENTITY_ID;
                            var human_stat_tracking__totalDangers : float?)
  if !isAlive || !beh_tree__enabled || length(agent_dangers.dangers) == 0 || act.curTime < agent_dangers__nextDangersTraceTime
    return

  agent_dangers__nextDangersTraceTime += agent_dangers__nextDangersTraceCheckTime

  let agentEid = eid
  let fromPos = agent_dangers__standShootPos
  let flags = (ETF_ALL) & ~(ETF_LMESH | ETF_HEIGHTMAP)
  var maxRatio = 0f
  var traceTo = INVALID_ENTITY_ID

  var targets : array<tuple<Target const?; float>>
  reserve(targets, length(agent_dangers.dangers))
  for danger in agent_dangers.dangers
    var found = false
    query(danger.eid) <| $ [es(REQUIRE=ai_target)] (ai_target : Target const?; ai_target__noiseLevel = 0.; beh_tree__enabled : bool = false)
      found = true
      let potentialDangerMeter = calc_danger(act.curTime, agent_dangers__maxDangerDist, danger, *ai_target, ai_target__noiseLevel, beh_tree__enabled,
                                             danger_calc__aiCoef, danger_calc__avoidBulletsNearTime,
                                             danger_calc__lastShootCoef, danger_calc__noiseCoef, danger_calc__lastBulletNearbyCoef)
      targets |> emplace([[auto ai_target, potentialDangerMeter]])
      let ratio = calc_traceable_ratio(act.curTime, potentialDangerMeter, danger)
      if ratio > maxRatio
        maxRatio = ratio
        traceTo = danger.eid
    if !found
      targets |> emplace([[tuple<Target const?; float>]])

  for i in iter_range(agent_dangers.dangers)
    assume danger = agent_dangers.dangers[i]
    let ai_target = targets[i]._first
    let potentialDangerMeter = targets[i]._last
    if ai_target == null || !ai_target.isAlive || ai_target.isHidden
      danger.dangerMeter = 0f
      danger.noiseMeter = 0f
      continue
    if danger.eid == traceTo && (maxRatio >= agent_dangers__minTraceableRatio || act.curTime - danger.lastTraceTime > agent_dangers__retraceTargetsTime)
      danger.lastTraceTime = act.curTime
      let dir = normalize(ai_target.targetPos - fromPos)
      let lmeshTracePos = fromPos + agent_dangers__hmapTraceOffset
      if human_stat_tracking__targetTracesCount != null
        (*human_stat_tracking__targetTracesCount)++
      let shootRayMat = get_shoot_ray_mat(human_attached_gun__attachedGunEid, human_weap__currentGunEid)
      var collides = (rayhit_normalized_lmesh(lmeshTracePos, dir, danger.distance) ||
                      rayhit_normalized(fromPos, dir, danger.distance, flags, shootRayMat) ||
                      traceTransparencyRayRIGenNormalized(fromPos, dir, danger.distance, 0.01) ||
                      rayhit_smoke_occluders(fromPos, ai_target.targetPos))

      let t = min(length(ai_target.targetPos - fromPos), danger.distance)
      if !collides
        find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], fromPos, dir, t, 0.0, GridEntCheck BOUNDING) <| $(objEid : EntityId)
          if objEid != danger.eid && objEid != agentEid
            query(objEid) <| $ [es] (transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent)
              collides = collres_rayhit(collres, transform, animchar.nodeTree, fromPos, dir, t)
          return collides
      danger.traceable = !collides

    danger.dangerMeter = danger.traceable ? potentialDangerMeter : 0.
    danger.dangerMeter *= agent_dangers_calc__dangerMeterMult

    danger.noiseMeter = potentialDangerMeter

    if human_stat_tracking__totalDangers != null
      *human_stat_tracking__totalDangers += float(length(agent_dangers.dangers)) * agent_dangers__nextDangersTraceCheckTime
