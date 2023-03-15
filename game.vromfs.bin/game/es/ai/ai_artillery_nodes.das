options always_export_initializer = true

require app
require ecs
require ecs.common
require math
require math.base
require BehNodes
require EnlistedWalkerai
require DagorDataBlock
require HumanPhys
require Dacoll
require pathfinder
require DagorRandom
require DagorMath
require strings
require player

require enlisted.events_enlisted
require enlisted.game.es.artillery_radio_common
require enlisted.game.es.artillery_aircraft_common
require enlisted.game.es.ai_poly_areas_common


def check_ai_bot_can_call_artillery(bot_eid : EntityId; type_index : int = -1)
  var result = false
  query(bot_eid) <| $ [es] (isAlive : bool;
                            isDowned : bool;
                            human_weap__radioEid : EntityId;
                            human_net_phys__isSwimming : bool = false;
                            human_net_phys__isClimbing : bool = false;
                            squad_member__playerEid : EntityId)
    if isAlive && !isDowned && !!human_weap__radioEid && !human_net_phys__isSwimming && !human_net_phys__isClimbing
      query(squad_member__playerEid) <| $ [es(REQUIRE=(playerIsBot))] (team aka player_team : int;
                                                                       artillery__availableAtTime : float;
                                                                       artillery__templates : StringList)
        let numArtilleryTypes = length(artillery__templates)
        if player_team >= 1 && ((type_index == -1 && numArtilleryTypes > 0) || (type_index >= 0 && type_index < numArtilleryTypes))
          let artilleryReady1 = type_index < 0 || !is_aircraft_request(squad_member__playerEid, type_index) || !is_aircraft_request_on_cooldown(player_team)
          let artilleryReady2 = get_sync_time() > artillery__availableAtTime
          let artilleryReady3 = !is_artillery_max_limit_reached(player_team)
          if artilleryReady1 && artilleryReady2 && artilleryReady3
            let sameTeamHumanHasRadio = find_query() <| $ [es(REQUIRE_NOT=playerIsBot)] (team aka other_player_team : int; artillery__hasRadioInArmySquads : bool)
              return other_player_team == player_team && artillery__hasRadioInArmySquads
            if !sameTeamHumanHasRadio
              result = true
  return result

def try_generate_ai_artillery_strike(bot_eid : EntityId;
                                     player_eid : EntityId;
                                     leader_target_eid_param_name : string;
                                     rand_dist : float2;
                                     var out_type_index : int;
                                     var out_pos : float3&;
                                     var out_pos_end : float3&;
                                     var out_delay_time : float&)
  var teamId = TEAM_UNASSIGNED
  var numTypes = 0
  var strikeAngle = 0.0
  var strikeDistance = float2()
  var strikeDelayTime = float2()
  var strikeMaxPoints = 0
  query(player_eid) <| $ [es] (team : int;
                               artillery__templates : StringList;
                               artillery__setupAIArtilleryAngle : float;
                               artillery__setupAIArtilleryDistance : float2;
                               artillery__setupAIArtilleryDelayTime : float2;
                               artillery__setupAIArtilleryMaxTryPoints : int = 50)
    teamId = team
    numTypes = length(artillery__templates)
    strikeAngle = deg_to_rad(abs(artillery__setupAIArtilleryAngle))
    strikeDistance = artillery__setupAIArtilleryDistance
    strikeDelayTime = artillery__setupAIArtilleryDelayTime
    strikeMaxPoints = artillery__setupAIArtilleryMaxTryPoints

  if !(teamId >= 1) || numTypes <= 0
    return false

  var typeIndex = 0
  var availableTypes : array<int>
  for i in range(numTypes)
    if check_ai_bot_can_call_artillery(bot_eid, i)
      push(availableTypes, i)
  let numAvailableTypes = length(availableTypes)
  if numAvailableTypes <= 0
    return false
  typeIndex = availableTypes[rnd_int(0, numAvailableTypes - 1)]

  var defendPos = float3()
  var defendRadius = 0.0
  var hasDefendPos = false
  query(bot_eid) <| $ [es] (squad_member__squad : EntityId)
    query(squad_member__squad) <| $ [es] (squad__regroupPos : float3; squad__leader : EntityId)
      defendPos = squad__regroupPos
      hasDefendPos = true
      if !empty(leader_target_eid_param_name)
        query(squad__leader) <| $ [es] (beh_tree : BehaviourTree)
          let paramId = beh_tree.blackBoard |> datablock_find_param(leader_target_eid_param_name)
          if paramId != -1
            let targetEid = EntityId(uint(beh_tree.blackBoard |> datablock_getInt(paramId)))
            query(targetEid) <| $ [es] (transform : float3x4; sphere_zone__radius : float = 0.0; capzone__approximateRadius : float = 0.0)
              defendPos = transform[3]
              defendRadius = sphere_zone__radius > 0.0 ? sphere_zone__radius : capzone__approximateRadius > 0.0 ? capzone__approximateRadius : 0.5 * min(length(transform[0]), length(transform[2]))
  if !hasDefendPos
    return false

  var respCount = 0.0
  var respMidPos = float3()
  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (active : bool; team : int; respawnbaseType : string; transform : float3x4)
    if !active || team == TEAM_UNASSIGNED || team == teamId || respawnbaseType != "human"
      return
    respCount += 1.0
    respMidPos += transform[3]
  if respCount <= 0.0
    return false
  respMidPos *= rcp(respCount)
  var strikeDir = respMidPos - defendPos
  strikeDir.y = 0.0

  let minDist = max(strikeDistance.x, defendRadius)
  let betweenDist = length(strikeDir)
  if betweenDist < minDist
    return false
  var maxDist = max(minDist, strikeDistance.y)
  if maxDist > betweenDist
    maxDist = betweenDist
  let minDistSq = square(minDist)
  let maxDistSq = square(maxDist)

  let strikeBaseAngle = atan2(strikeDir.z, strikeDir.x)

  let isTrainBehavior = find_query() <| $ [es(REQUIRE=aiTrainBehaviour)] ()
    return true
  var trainVel = 0.0
  var attackTrain = true
  if isTrainBehavior
    query() <| $ [es] (train__expectedVelocity : float; train__teamDefense : int)
      trainVel = train__expectedVelocity
      attackTrain = teamId == train__teamDefense

  var enemyCount = 0.0
  var enemyMidPos = float3()
  var enemyPositions : array<float3>
  var enemyOnTrain : array<bool>
  query() <| $ [es(REQUIRE=squad_member__squad)] (transform : float3x4;
                                                  squad_member__playerEid : EntityId;
                                                  beh_tree__isAgentOnTrain : bool;
                                                  isAlive : bool)
    if !isAlive
      return
    query(squad_member__playerEid) <| $ [es] (team : int)
      if team == teamId || team == TEAM_UNASSIGNED
        return
      if isTrainBehavior
        if attackTrain || !beh_tree__isAgentOnTrain
          enemyCount += 1.0
          enemyMidPos += transform[3]
          enemyPositions |> push(transform[3])
          enemyOnTrain |> push(beh_tree__isAgentOnTrain)
        return
      let dir = transform[3] - defendPos
      let distSq = length_sq(dir)
      if distSq >= minDistSq && distSq <= maxDistSq
        let angle = atan2(dir.z, dir.x)
        let deltaAngle = norm_s_ang(angle - strikeBaseAngle)
        if abs(deltaAngle) <= strikeAngle
          enemyCount += 1.0
          enemyMidPos += transform[3]
          enemyPositions |> push(transform[3])
          enemyOnTrain |> push(beh_tree__isAgentOnTrain)
  if enemyCount <= 0.0
    return false
  enemyMidPos *= rcp(enemyCount)

  var targetEnemyPos = float3()
  var targetEnemyOnTrain = false
  var bestPositionDistSq = VERY_BIG_NUMBER
  for i, position in iter_range(enemyPositions), enemyPositions
    let distSq = distance_sq(position, enemyMidPos)
    if distSq < bestPositionDistSq
      bestPositionDistSq = distSq
      targetEnemyPos = position
      targetEnemyOnTrain = enemyOnTrain[i]

  var randDistRange = rand_dist

  if isTrainBehavior
    randDistRange = float2(1.0, 5.0)
    var botPos = targetEnemyPos
    query(bot_eid) <| $ [es] (transform : float3x4)
      botPos = transform[3]
    if distance(botPos, targetEnemyPos) < strikeDistance.x
      return false
    let aheadTime = rnd_float(23.0, 27.0)
    let delta = botPos - targetEnemyPos
    if targetEnemyOnTrain
      targetEnemyPos += normalize(delta) * trainVel * aheadTime
    else
      let humanVel = 3.0
      var diff = normalize(delta) * humanVel * aheadTime
      if length_sq(diff) > length_sq(delta * 0.5)
        diff = delta * 0.5
      targetEnemyPos += diff

  for _i in range(strikeMaxPoints)
    var targetPos = targetEnemyPos
    let randAngle = rnd_float(0.0, TWOPI)
    let randDist = rnd_float(randDistRange.x, randDistRange.y)
    targetPos.x += cos(randAngle) * randDist
    targetPos.z += sin(randAngle) * randDist

    var foundProjectedPos = false
    let extents = float3(3.0, 1000.0, 3.0)
    var polyRef : dtPolyRef = uint64(0)
    if project_to_nearest_navmesh_point(targetPos, extents, polyRef)
      var polyArea : uint8 = uint8(0)
      if get_poly_area(polyRef, polyArea)
        foundProjectedPos = polyArea != uint8(EnlPolyArea POLYAREA_WATER)

    let skyPos = targetPos + float3(0.0, 1000.0, 0.0)
    var downHeight = 1000.0
    let maxHeightDiff = 3.33
    tracedown_normalized(skyPos, downHeight, ETF_DEFAULT)
    if abs(downHeight - 1000.0) > maxHeightDiff
      foundProjectedPos = false

    if foundProjectedPos
      out_pos = targetPos
      out_pos_end = targetPos
      out_type_index = typeIndex

      if is_aircraft_request(player_eid, typeIndex)
        let aircraftDir = calc_aircraft_request_dir(teamId)
        let aircraftDist = rnd_float(10.0, 20.0)
        out_pos = out_pos_end - float3(aircraftDir.x * aircraftDist, 0.0, aircraftDir.y * aircraftDist)

      if test_artillery_in_battle_area(out_pos, out_pos_end, teamId)
        out_delay_time = isTrainBehavior ? 0.0 : rnd_float(strikeDelayTime.x, strikeDelayTime.y)
        return true
  return false


[beh_node(name="tryCallArtillery")]
class TryCallArtilleryNode : BehNodeAdapter
  initRange : float2 = float2(30.0)
  repeatRange : float2 = float2(60.0)
  callTime : float = 5.0
  callTimer : float = 0.0
  callingAtTime : float = 0.0
  callRetryTime : float2 = float2(5.0, 10.0)
  leaderTargetEidParamName : string
  randDist : float2 = float2(5.0, 15.0)

  def override loadFromBlk(var data : DataBlock) : void
    initRange = datablock_getPoint2(data, "initRange", initRange)
    repeatRange = datablock_getPoint2(data, "repeatRange", repeatRange)
    callTime = datablock_getReal(data, "callTime", callTime)
    callRetryTime = datablock_getPoint2(data, "callRetryTime", callRetryTime)
    leaderTargetEidParamName = datablock_getStr(data, "leaderTargetEidParam", "leaderTargetEid")
    randDist = datablock_getPoint2(data, "randDist", randDist)

  def override init() : void
    callTimer = 0.0

  def override exit() : void
    var agent = beh_tree_entity_agent(*owner)
    var phys = agent.phys
    if phys != null
      phys.producedCT |> human_control_state_set_device_state(false)
    if callTimer > 0.0
      query(beh_tree_eid(owner)) <| $ [es] (squad_member__playerEid : EntityId)
        query(squad_member__playerEid) <| $ [es] (var artillery__nextTimeAICallArtillery : float&)
          artillery__nextTimeAICallArtillery = callingAtTime
    callTimer = 0.0

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    if !check_ai_bot_can_call_artillery(agent.eid)
      return EBehResult ER_FAILED

    var playerEid = INVALID_ENTITY_ID
    query(agent.eid) <| $ [es] (squad_member__playerEid : EntityId)
      playerEid = squad_member__playerEid

    if callTimer > 0.0
      var phys = agent.phys
      if phys != null
        assume ct = phys.producedCT
        ct |> human_control_state_set_neutral_ctrl()
        ct |> human_control_state_set_walk_speed(0.f)
        ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, false)
        ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)
        ct |> human_control_state_set_device_state(true)

      callTimer -= dt
      if callTimer > 0.0
        return EBehResult ER_RUNNING
      callTimer = 0.0

      var typeIndex : int
      var pos : float3
      var posEnd : float3
      var delayTime : float
      if try_generate_ai_artillery_strike(agent.eid, playerEid, leaderTargetEidParamName, randDist, typeIndex, pos, posEnd, delayTime)
        if delayTime <= 0.0
          sendEvent(playerEid, [[CmdStartArtilleryStrikeAtPos owner=agent.eid, pos=pos, typeIndex=typeIndex, posEnd=posEnd]])
        else
          sendEvent(playerEid, [[CmdStartDelayedArtilleryStrikeAtPos owner=agent.eid, pos=pos, typeIndex=typeIndex, posEnd=posEnd, delayTime=delayTime]])
        return EBehResult ER_SUCCESS

      query(playerEid) <| $ [es] (var artillery__nextTimeAICallArtillery : float&)
        artillery__nextTimeAICallArtillery = get_sync_time() + rnd_float(callRetryTime.x, callRetryTime.y)
      return EBehResult ER_FAILED

    var callArtillery = false
    query(playerEid) <| $ [es] (var artillery__nextTimeAICallArtillery : float&)
      let curTime = get_sync_time()
      if artillery__nextTimeAICallArtillery <= 0.0
        artillery__nextTimeAICallArtillery = rnd_float(initRange.x, initRange.y)
      elif curTime >= artillery__nextTimeAICallArtillery
        callingAtTime = curTime
        artillery__nextTimeAICallArtillery = curTime + rnd_float(repeatRange.x, repeatRange.y)
        callArtillery = true

    if callArtillery
      callTimer = callTime
      return EBehResult ER_RUNNING

    return EBehResult ER_FAILED


[beh_node(name="prepareArtillery")]
class PrepareArtillery : BehNodeAdapter
  requesterEidParam : int = -1
  shouldSendParam : int = -1
  typeIndexParam : int = -1
  posEndParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    requesterEidParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "targetUnitParam", "artilleryRequester"), 0)
    shouldSendParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "shouldSendParamName", "artilleryShouldSend"), false)
    typeIndexParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "typeIndexParamName", "artilleryTypeIndex"), 0)
    posEndParam = owner.blackBoard |> get_or_create(datablock_getStr(data, "posEndParamName", "artilleryPosEnd"), float3())

  def override exit()
    var agent = beh_tree_entity_agent(*owner)
    var phys = agent.phys
    if phys != null
      phys.producedCT |> human_control_state_set_device_state(false)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    let requesterEid = EntityId(uint(owner.blackBoard |> datablock_getInt(requesterEidParam)))
    var playerRequester = INVALID_ENTITY_ID
    query(requesterEid) <| $ [es(REQUIRE_NOT=deadEntity)] (possessedByPlr : EntityId)
      playerRequester = possessedByPlr
    if !playerRequester
      return EBehResult ER_FAILED

    var res = EBehResult ER_FAILED
    query(agent.eid) <| $ [es] (human_weap__radioMode : bool;
                                squad_member__orderPosition : float3;
                                human_weap__radioEid : EntityId = INVALID_ENTITY_ID)
      if !human_weap__radioEid
        res = EBehResult ER_FAILED
        return
      if human_weap__radioMode && owner.blackBoard |> datablock_getBool(shouldSendParam)
        let typeIndex = owner.blackBoard |> datablock_getInt(typeIndexParam)
        let posEnd = owner.blackBoard |> datablock_getPoint3(posEndParam)
        sendEvent(playerRequester, [[CmdStartArtilleryStrikeAtPos owner=requesterEid, pos=squad_member__orderPosition, typeIndex=typeIndex, posEnd=posEnd]])
        res = EBehResult ER_SUCCESS
        return
      res = EBehResult ER_RUNNING

    var phys = agent.phys
    if phys != null
      assume ct = phys.producedCT
      ct |> human_control_state_set_neutral_ctrl()
      ct |> human_control_state_set_walk_speed(0.f)
      ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, false)
      ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)
      ct |> human_control_state_set_device_state(true)

    return res
