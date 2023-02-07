options always_export_initializer = true

require ecs
require ecs.common
require EnlistedNet
require DagorDataBlock
require BehNodes
require EnlistedWalkerai
require app
require strings
require math.base
require inventory
require walkerai
require HumanPhys
require DagorRandom
require EnlistedHuman
require common_shooter.es.squad_common
require common_shooter.es.ai.common_shooter_walker_nodes_common
require common_shooter.events_common_shooter


[beh_node(name="useMedkit")]
class UseMedkit : BehNodeAdapter
  syncDelayExtraTime : float = 0.5

  eventWasSent : bool = false
  waitTime : float = 0f

  def override loadFromBlk(var data : DataBlock) : void
    syncDelayExtraTime = data |> datablock_getReal("syncDelayExtraTime", syncDelayExtraTime)

  def override init() : void
    eventWasSent = false
    waitTime = 0f

  def override update(dt : float) : EBehResult
    let eid = beh_tree_eid()

    if !eventWasSent
      eventWasSent = true
      sendEvent(eid, [[CmdMedkitUse]])
      waitTime = syncDelayExtraTime
    else
      query(eid) <| $ [es] (human_inventory__entityToUse : EntityId; human_inventory__entityUseEnd : float)
        if has(human_inventory__entityToUse, "item__healAmount")
          waitTime = human_inventory__entityUseEnd - get_sync_time() + syncDelayExtraTime

    waitTime -= dt
    return waitTime > 0f ? EBehResult ER_RUNNING : EBehResult ER_SUCCESS

[beh_node(name="isInBlindness")]
class IsInBlindness : BehNodeAdapter
  blindnessTimeEndParam : int = -1
  earlyReleaseTime : float = 0.5

  def override loadFromBlk(var data : DataBlock) : void
    blindnessTimeEndParam = owner.blackBoard |> get_or_create("blindness.timeEnd", 0f)
    earlyReleaseTime = data |> datablock_getReal("earlyReleaseTime", earlyReleaseTime)

  def override update(dt : float) : EBehResult
    let timeEnd = owner.blackBoard |> datablock_getReal(blindnessTimeEndParam) - earlyReleaseTime
    return timeEnd > get_sync_time() ? EBehResult ER_SUCCESS : EBehResult ER_FAILED


[beh_node(name="inBlindness")]
class InBlindness : BehNodeAdapter
  blindnessTimeEndParam : int = -1
  earlyReleaseTime : float = 0.5
  isStarted : bool = false

  def override loadFromBlk(var data : DataBlock) : void
    blindnessTimeEndParam = owner.blackBoard |> get_or_create("blindness.timeEnd", 0f)
    earlyReleaseTime = data |> datablock_getReal("earlyReleaseTime", earlyReleaseTime)

  def override init()
    isStarted = false

  def override update(dt : float) : EBehResult
    let timeEnd = owner.blackBoard |> datablock_getReal(blindnessTimeEndParam) - earlyReleaseTime
    if timeEnd > get_sync_time()
      if !isStarted
        isStarted = true
        var agent = beh_tree_entity_agent(*owner)
        var phys = agent.phys
        if phys != null
          phys.producedCT |> human_control_state_set_walk_speed(0f)
      return EBehResult ER_RUNNING
    return EBehResult ER_SUCCESS


[beh_node(name="extinguish")]
class Extinguish : BehNodeAdapter
  eventSent : bool = false

  def override init()
    eventSent = false

  def override update(dt : float) : EBehResult
    let eid = beh_tree_eid()
    if !eventSent
      eventSent = true
      send_net_event(eid, [[CmdPutOutFireStart]])

    let burning = get_bool(eid, "burning__isBurning") ?? false
    return burning ? EBehResult ER_RUNNING : EBehResult ER_SUCCESS


[beh_node(name="reviving")]
class Reviving : BehNodeAdapter
  startTime : float = -1.

  def override update(dt : float) : EBehResult
    var res = EBehResult ER_SUCCESS
    query(beh_tree_eid()) <| $ [es] (eid : EntityId;
                                     hitpoints__revivingCount : int = 0;
                                     human_inventory__savedUseProgress : float = 0.;
                                     human_inventory__entityUseEnd : float = -1.;
                                     total_kits__selfRevive : int = 0)
      if hitpoints__revivingCount != 0 || human_inventory__savedUseProgress > 0.
        res = EBehResult ER_RUNNING
        return

      let entityUseEnd = human_inventory__entityUseEnd
      let curTime = get_sync_time()
      if entityUseEnd + 0.3 > curTime || startTime + 0.3 > curTime
        res = EBehResult ER_RUNNING
        return

      if total_kits__selfRevive > 0
        startTime = curTime;
        sendEvent(eid, [[CmdMedkitUse]])
        res = EBehResult ER_RUNNING
        return

    return res


[beh_node(name="isAgentPlayerBot")]
class IsAgentPlayerBot : BehNodeAdapter
  def override update(dt : float) : EBehResult
    var isBot = false
    query(beh_tree_eid()) <| $ [es] (squad_member__playerEid : EntityId)
      query(squad_member__playerEid) <| $ [es(REQUIRE=playerIsBot)] ()
        isBot = true
    return isBot ? EBehResult ER_SUCCESS : EBehResult ER_FAILED


def find_best_grenade_ammo_item_id(item_container : EidList; grenade_types_list : StringList;
                                   use_exclude_list : bool; exclude_grenade_types_list : StringList) : int
  var bestItemId = INVALID_ITEM_ID
  var bestItemIdPriority = -1
  if empty(grenade_types_list)
    return bestItemId
  var found = false
  for itemEid in item_container
    query(itemEid) <| $ [es] (item__grenadeType : string; item__id : int)
      let idx = find_index(grenade_types_list, item__grenadeType)
      if idx != -1 && (!use_exclude_list || find_index(exclude_grenade_types_list, item__grenadeType) < 0)
        let foundItemIdPriority = idx
        if bestItemIdPriority == -1 || foundItemIdPriority < bestItemIdPriority
          bestItemIdPriority = foundItemIdPriority
          bestItemId = item__id
          if foundItemIdPriority == 0
            found = true
            return
    if found
      break
  return bestItemId

[beh_node(name="chooseBestWeapon")]
class ChooseBestWeapon : BehNodeAdapter
  targetParam : int = -1
  selectWeapon : bool = true
  defaultCombatDist : float = 20.0

  changeWeaponTimeParam : int = -1
  changeWeaponDelay : float2 = float2(7.0, 15.0)
  switchRadiusCoef : float = 1.0

  allowGrenades : bool = false

  def override loadFromBlk(var data : DataBlock) : void
    let targetParamName = data |> datablock_getStr("targetParam", "")
    if !empty(targetParamName)
      targetParam = owner.blackBoard |> get_or_create(targetParamName, 0)
    selectWeapon = data |> datablock_getBool("selectWeapon", selectWeapon)
    defaultCombatDist = data |> datablock_getReal("defaultCombatDist", defaultCombatDist)

    let changeWeaponTimeParamName = data |> datablock_getStr("changeWeaponTimeParam", "nextChangeWeaponTime")
    if !empty(changeWeaponTimeParamName)
      changeWeaponTimeParam = owner.blackBoard |> get_or_create(changeWeaponTimeParamName, 0.0)
    changeWeaponDelay = data |> datablock_getPoint2("changeWeaponDelay", changeWeaponDelay)
    switchRadiusCoef = data |> datablock_getReal("switchRadiusCoef", switchRadiusCoef)

    allowGrenades = data |> datablock_getBool("allowGrenades", allowGrenades)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED
    if agent.phys == null
      return EBehResult ER_FAILED

    var unarmed = false
    query(agent.eid) <| $ [es] (human_unarmed__active : bool)
      unarmed = human_unarmed__active
    if unarmed
      return EBehResult ER_FAILED

    var agentPlayerEid = INVALID_ENTITY_ID
    query(agent.eid) <| $ [es] (squad_member__playerEid : EntityId)
      agentPlayerEid = squad_member__playerEid

    var vehicleTarget = false
    var distToTargetSq = square(defaultCombatDist)
    var targetInVehicle = false
    let targetUnitId = targetParam >= 0 ? owner.blackBoard |> datablock_getInt(targetParam) : 0
    query(EntityId(uint(targetUnitId))) <| $ [es] (ai_target : Target;
                                                   agent_dangers__tag : string = "";
                                                   isInVehicle : bool = false)
      vehicleTarget = agent_dangers__tag == "vehicle"
      distToTargetSq = length_sq(ai_target.targetPos - agent.pos)
      targetInVehicle = isInVehicle

    if vehicleTarget
      let curTime = get_sync_time()
      var allowedToThrowGrenade = true
      query(agentPlayerEid) <| $ [es(REQUIRE=playerIsBot)] (botPlayer__nextAllowedThrowAntiTankGrenadeTime : float;
                                                            botPlayer__throwAntiTankGrenadeCounter : int;
                                                            botPlayer__throwAntiTankGrenadeDist : float2)
        allowedToThrowGrenade = false
        if botPlayer__throwAntiTankGrenadeCounter > 0 || curTime >= botPlayer__nextAllowedThrowAntiTankGrenadeTime
          if distToTargetSq >= square(botPlayer__throwAntiTankGrenadeDist.x) && distToTargetSq <= square(botPlayer__throwAntiTankGrenadeDist.y)
            allowedToThrowGrenade = true
      if !allowedToThrowGrenade
        return EBehResult ER_FAILED
      var foundGrenade = false
      query(agent.eid) <| $ [es] (itemContainer : EidList; [[shared_comp]] beh_tree__antitankGrenades : StringList)
        let grenadeItemId = find_best_grenade_ammo_item_id(itemContainer, beh_tree__antitankGrenades, false, beh_tree__antitankGrenades);
        if grenadeItemId != INVALID_ITEM_ID
          foundGrenade = true
          if selectWeapon
            sendEvent(agent.eid, [[CmdSetWishAmmoItemType slot_id=int(HUWeaponSlots EWS_GRENADE), item_id=grenadeItemId]])
            query(agentPlayerEid) <| $ [es(REQUIRE=playerIsBot)] (var botPlayer__nextAllowedThrowAntiTankGrenadeTime : float&;
                                                                  var botPlayer__throwAntiTankGrenadeCounter : int&;
                                                                  botPlayer__throwAntiTankGrenadeCounterReset : int2;
                                                                  botPlayer__throwAntiTankGrenadeDelay : float2)
              if botPlayer__throwAntiTankGrenadeCounter > 0
                --botPlayer__throwAntiTankGrenadeCounter
              else
                botPlayer__nextAllowedThrowAntiTankGrenadeTime = curTime + rnd_float(botPlayer__throwAntiTankGrenadeDelay.x, botPlayer__throwAntiTankGrenadeDelay.y)
                botPlayer__throwAntiTankGrenadeCounter = rnd_int(botPlayer__throwAntiTankGrenadeCounterReset.x, botPlayer__throwAntiTankGrenadeCounterReset.y)
      return foundGrenade ? EBehResult ER_SUCCESS : EBehResult ER_FAILED

    if allowGrenades && !targetInVehicle
      let curTime = get_sync_time()
      var allowedToThrowGrenade = false
      var agentTeam = -1
      var tanksNearDistanceSq = 0.0
      var tanksNearChance = 1.0
      query(agentPlayerEid) <| $ [es(REQUIRE=playerIsBot)] (team aka player_team : int;
                                                            botPlayer__saveGrenadesForEnemyTanksDistance : float;
                                                            botPlayer__saveGrenadesForEnemyTanksChance : float;
                                                            botPlayer__nextAllowedThrowGrenadeTime : float;
                                                            botPlayer__throwGrenadeDist : float2)
        if curTime >= botPlayer__nextAllowedThrowGrenadeTime
          if distToTargetSq >= square(botPlayer__throwGrenadeDist.x) && distToTargetSq <= square(botPlayer__throwGrenadeDist.y)
            allowedToThrowGrenade = true
            agentTeam = player_team
            tanksNearDistanceSq = square(botPlayer__saveGrenadesForEnemyTanksDistance)
            tanksNearChance = botPlayer__saveGrenadesForEnemyTanksChance
      if allowedToThrowGrenade
        var foundGrenade = false
        query(agent.eid) <| $ [es] (itemContainer : EidList; [[shared_comp]] beh_tree__antibotGrenades : StringList; [[shared_comp]] beh_tree__antitankGrenades : StringList)
          var grenadeItemId = find_best_grenade_ammo_item_id(itemContainer, beh_tree__antibotGrenades, true, beh_tree__antitankGrenades)
          if grenadeItemId == INVALID_ITEM_ID
            grenadeItemId = find_best_grenade_ammo_item_id(itemContainer, beh_tree__antibotGrenades, false, beh_tree__antitankGrenades)
            if grenadeItemId != INVALID_ITEM_ID && agentTeam >= 1
              let enemyTanksAround = find_query() <| $ [es(REQUIRE=isTank, REQUIRE_NOT=deadEntity)] (team aka tank_team : int; transform aka tank_transform : float3x4)
                return tank_team >= 1 && tank_team != agentTeam && distance_sq(tank_transform[3], agent.pos) < tanksNearDistanceSq
              if enemyTanksAround && (tanksNearChance >= 1.0 || rnd_float(0.0, 1.0) < tanksNearChance)
                grenadeItemId = INVALID_ITEM_ID
          if grenadeItemId != INVALID_ITEM_ID
            foundGrenade = true
            if selectWeapon
              sendEvent(agent.eid, [[CmdSetWishAmmoItemType slot_id=int(HUWeaponSlots EWS_GRENADE), item_id=grenadeItemId]])
              query(agentPlayerEid) <| $ [es(REQUIRE=playerIsBot)] (var botPlayer__nextAllowedThrowGrenadeTime : float&; botPlayer__throwGrenadeDelay : float2)
                botPlayer__nextAllowedThrowGrenadeTime = curTime + rnd_float(botPlayer__throwGrenadeDelay.x, botPlayer__throwGrenadeDelay.y)
        if foundGrenade
          return EBehResult ER_SUCCESS

    let currWeapon = int(agent.phys.producedCT.chosenWeapon)
    var currAllowed = false
    var bestWeapons : array<int>
    var goodWeapon = -1
    var otherWeapon = -1
    var otherWeaponPriority = 0
    query(agent.eid) <| $ [es] (human_weap__gunEids : EidList)
      var closestStartFireRange = 0.0
      for i, gunEid in range(int(HUWeaponSlots EWS_NUM)), human_weap__gunEids
        if gunEid == INVALID_ENTITY_ID || i == int(HUWeaponSlots EWS_GRENADE)
          continue
        if i == int(HUWeaponSlots EWS_MELEE)
          if otherWeaponPriority == 0 && otherWeapon == -1
            otherWeapon = i
          continue

        var allowedGun = false
        var firingRange = float2()
        query(gunEid) <| $ [es] (specialAIWeaponType : int const?; combatFiringRange : float2;
                                 gun__totalAmmo : int = 0; gun__ammo : int = 0; gun__isOverheat : bool = false)
          let isCurrent = i == currWeapon
          allowedGun = (gun__totalAmmo + gun__ammo) > 0 && !gun__isOverheat
          if allowedGun && specialAIWeaponType != null
            if *specialAIWeaponType == 1 // rocket launchers (not implemented yet)
              allowedGun = false
              if otherWeaponPriority == 0
                otherWeapon = i
            elif *specialAIWeaponType == 2 // pistols
              otherWeapon = i
              otherWeaponPriority = 10
              allowedGun = isCurrent
            elif *specialAIWeaponType == 3 // antitank rifles
              allowedGun = false
              if otherWeaponPriority < 10
                otherWeapon = i
                otherWeaponPriority = 5
          let rangeCoef = isCurrent ? 1.0 : switchRadiusCoef
          firingRange = float2(combatFiringRange.x, combatFiringRange.y * rangeCoef)
        if !allowedGun
          continue

        if currWeapon == i
          currAllowed = true
        if square(firingRange.y) < distToTargetSq
          if otherWeapon == -1
            otherWeapon = i
          continue
        if square(firingRange.x) < distToTargetSq
          bestWeapons |> push(i)
        elif goodWeapon == -1 || firingRange.x < closestStartFireRange
          closestStartFireRange = firingRange.x
          goodWeapon = i

    var bestWeapon = -1
    let nextChangeWeaponTime = changeWeaponTimeParam >= 0 ? owner.blackBoard |> datablock_getReal(changeWeaponTimeParam) : 0.0
    if !currAllowed || get_sync_time() >= nextChangeWeaponTime
      if !empty(bestWeapons)
        bestWeapon = bestWeapons[rnd_int(0, length(bestWeapons) - 1)]
      else
        bestWeapon = goodWeapon >= 0 ? goodWeapon : otherWeapon
    else
      bestWeapon = currWeapon

    if bestWeapon >= 0
      if selectWeapon && bestWeapon != currWeapon
        set_chosen_weapon(agent.phys.producedCT, HUWeaponSlots(bestWeapon))
        if changeWeaponTimeParam >= 0
          owner.blackBoard |> set(changeWeaponTimeParam, get_sync_time() + rnd_float(changeWeaponDelay.x, changeWeaponDelay.y))
      return EBehResult ER_SUCCESS
    return EBehResult ER_FAILED

[beh_node(name="resetGrenadeThrowTime")]
class ResetGrenadeThrowTime : BehNodeAdapter
  def override update(dt : float) : EBehResult
    query(beh_tree_eid()) <| $ [es] (squad_member__playerEid : EntityId)
      query(squad_member__playerEid) <| $ [es(REQUIRE=playerIsBot)] (var botPlayer__nextAllowedThrowGrenadeTime : float&)
        botPlayer__nextAllowedThrowGrenadeTime = get_sync_time()
    return EBehResult ER_SUCCESS

[beh_node(name="resetAntiTankGrenadeThrowLimiter")]
class ResetAntiTankGrenadeThrowLimiter : BehNodeAdapter
  def override update(dt : float) : EBehResult
    query(beh_tree_eid()) <| $ [es] (squad_member__playerEid : EntityId)
      query(squad_member__playerEid) <| $ [es(REQUIRE=playerIsBot)] (var botPlayer__throwAntiTankGrenadeCounter : int&)
        ++botPlayer__throwAntiTankGrenadeCounter
    return EBehResult ER_SUCCESS

[beh_node(name="isGrenadeSelected")]
class IsGrenadeSelected : BehNodeAdapter
  def override update(dt : float) : EBehResult
    let agent = beh_tree_entity_agent(*owner)
    return agent.phys.producedCT.chosenWeapon == HUWeaponSlots EWS_GRENADE ? EBehResult ER_SUCCESS : EBehResult ER_FAILED

[beh_node(name="isMeleeWeaponSelected")]
class IsMeleeWeaponSelected : BehNodeAdapter
  def override update(dt : float) : EBehResult
    let agent = beh_tree_entity_agent(*owner)
    return agent.phys.producedCT.chosenWeapon == HUWeaponSlots EWS_MELEE ? EBehResult ER_SUCCESS : EBehResult ER_FAILED

[beh_node(name="isBipodWeaponSelected")]
class IsBipodWeaponSelected : BehNodeAdapter
  def override update(dt : float) : EBehResult
    let agent = beh_tree_entity_agent(*owner)
    let chosenWeapon = int(agent.phys.appliedCT.chosenWeapon)
    var hasBipodWeaponSelected = false
    query(agent.eid) <| $ [es] (human_weap__gunEids : EidList)
      if chosenWeapon >= 0 && chosenWeapon < length(human_weap__gunEids)
        query(human_weap__gunEids[chosenWeapon]) <| $ [es] ([[shared_comp]] gun__mountPoints : Array)
          for i in iter_range(gun__mountPoints)
            let obj = get_ecs_object(gun__mountPoints[i])
            var pttype = get_ecs_string(obj, "type")
            if pttype != null && string(*pttype) == "bipod"
              hasBipodWeaponSelected = true
              break
    return hasBipodWeaponSelected ? EBehResult ER_SUCCESS : EBehResult ER_FAILED
