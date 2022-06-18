require ecs
require ecs.common
require EnlistedWalkerai
require DagorDataBlock
require BehNodes
require game.es.events
require game.es.sound_net.sound_net_events
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common

def squadmate_attack_order_speech(squadmate_eid : ecs::EntityId; leader_eid : ecs::EntityId; squad_member_response = "confirm")
  sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadAttackOrder", importance=1.]])
  if squad_member_response != ""
    request_squad_member_response(squadmate_eid, squad_member_response)

def has_antitank_grenade(eid : EntityId) : bool
  var res = false
  ecs::query(eid) <| $ [es] (itemContainer : EidList; [[shared_comp]] beh_tree__antitankGrenades : StringList)
    for itemEid in itemContainer
      let itemGrenadeType = get_string(itemEid, "item__grenadeType", "")
      let typeIdx = find_index(beh_tree__antitankGrenades, itemGrenadeType)
      if typeIdx != -1
        res = true
        return
  return res

def is_squadmate_suitable_for_attack(eid : EntityId; is_target_vehicle : bool) : bool
  return !is_target_vehicle || has_antitank_grenade(eid)

def order_attack(squadmate_eid, squad__leader, attack_target : EntityId)
  var isOrdered = false
  query(squadmate_eid) <| $ [es] (var squad_member__orderType : int&;
                                  var squad_member__orderPosition : float3&;
                                  var squad_member__orderUseEntity : EntityId&;
                                  var beh_tree : BehaviourTree&)
    beh_tree.blackBoard |> datablock_setInt("attackTarget", int(uint(attack_target)))
    squad_member__orderType = int(SquadMateOrder ESMO_ATTACK_TARGET)
    squad_member__orderPosition = float3()
    squad_member__orderUseEntity = attack_target
    squadmate_attack_order_speech(squadmate_eid, squad__leader, "confirm")
    send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_ATTACK_TARGET}")
    isOrdered = true

  if !isOrdered
    squadmate_attack_order_speech(squadmate_eid, squad__leader, "reject")
    sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="attack_target/cancelled"]])
    send_order_cancel_bq(squad__leader, "no_antitank_grenade", "{SquadMateOrder ESMO_ATTACK_TARGET}")

def squad_order_attack(squad_eid, squad__leader, attack_target : EntityId)
  let isTargetVehicle = has(attack_target, "vehicle");
  let nearestTeammate = get_nearest_squad_mate_not_ordered(squad_eid, squad__leader) <| $(eid : EntityId)
    var isPersonalOrder = false
    query(eid) <| $ [es] (squad_member__isPersonalOrder : bool)
      isPersonalOrder = squad_member__isPersonalOrder
    return !isPersonalOrder && is_squadmate_suitable_for_attack(eid, isTargetVehicle)

  order_attack(nearestTeammate.eid, squad__leader, attack_target)

def personal_order_attack(squadmate_eid, squad_member__squad, attack_target : EntityId)
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
    let isTargetVehicle = has(attack_target, "vehicle");
    let memberEid = is_squadmate_suitable_for_attack(squadmate_eid, isTargetVehicle) ? squadmate_eid : INVALID_ENTITY_ID
    order_attack(memberEid, squad__leader, attack_target)

[es(tag = server, no_order)]
def squadmate_reset_attack_order_es(act : UpdateStageInfoAct;
                                    eid : EntityId;
                                    beh_tree : BehaviourTree;
                                    var squad_member__orderType : int&;
                                    var squad_member__orderPosition : float3&;
                                    var squad_member__orderUseEntity : EntityId&;
                                    var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType == int(SquadMateOrder ESMO_ATTACK_TARGET) && beh_tree.blackBoard |> datablock_getInt("attackTarget", 0) == 0
    reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
    send_order_cancel_bq(eid, "no_attack_target", "{SquadMateOrder ESMO_ATTACK_TARGET}")

[es(tag = server)]
def on_squadmate_attack_order(evt : RequestSquadMateOrder; eid : EntityId; squad__leader : EntityId)
  if evt.orderType == SquadMateOrder ESMO_ATTACK_TARGET
    squad_order_attack(eid, squad__leader, evt.orderUseEntity)

[es(tag=server)]
def on_personal_squadmate_attack_order(evt : RequestPersonalSquadMateOrder;
                                       eid : EntityId;
                                       squad_member__squad : EntityId;
                                       var squad_member__isPersonalOrder : bool&)
  if evt.orderType == int(SquadMateOrder ESMO_ATTACK_TARGET)
    squad_member__isPersonalOrder = true
    personal_order_attack(eid, squad_member__squad, evt.orderUseEntity)