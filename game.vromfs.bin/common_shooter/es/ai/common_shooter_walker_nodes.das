options always_export_initializer = true

require ecs
require EnlistedNet
require DagorDataBlock
require BehNodes
require EnlistedWalkerai
require app
require HumanPhys
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
        let agent = beh_tree_entity_agent(*owner)
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
