require ecs
require DngWalkerai
require pathfinder
require DagorDataBlock
require BehNodes
require DagorRandom
require math
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require human_sounds_net.modules.human_sounds_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require DngBehTree
require game.es.squad_order_common

def order_heal(squad_eid, squad__leader : EntityId; squad__numAliveMembers : int) : bool
  let isLeaderDowned = get_bool(squad__leader, "isDowned") ?? false
  var ordered = false
  let nearestTeammate = get_nearest_squad_mate_for_order(squad_eid, squad__leader, SquadMateOrder ESMO_HEAL) <| $(eid : EntityId)
    return isLeaderDowned ? (get_int(eid, "total_kits__targetRevive") ?? 0 > 0) : (get_int(eid, "total_kits__targetHeal") ?? 0 > 0)
  if nearestTeammate.executeOrder
    return true
  query(nearestTeammate.eid) <| $ [es] (beh_tree__isInTrainBeh : bool;
                                        beh_tree__data__orderReq : string;
                                        beh_tree__data__healReq : string;
                                        var squad_member__orderType : int&;
                                        var squad_member__orderPosition : float3&;
                                        var squad_member__orderUseEntity : EntityId&;
                                        var squad_member__isPersonalOrder : bool&;
                                        var beh_tree : BehaviourTree&;
                                        var beh_tree__refs__behaviour : das_string&;
                                        var beh_tree__refs__orderType : das_string&;
                                        var beh_tree__latencyLoadBlackBoard : Object?)
    if beh_tree__isInTrainBeh
      return

    beh_tree__refs__behaviour := beh_tree__data__orderReq
    beh_tree__refs__orderType := beh_tree__data__healReq

    // NOTE: not using reload_squad_mate_beh_tree() here intentionally
    DngBehTree::load_beh_tree_from_ecs(nearestTeammate.eid)

    if beh_tree__latencyLoadBlackBoard != null
      *beh_tree__latencyLoadBlackBoard |> set("healRequester", int(uint(squad__leader)))
    beh_tree.blackBoard |> set("healRequester", int(uint(squad__leader)))

    squad_member__orderType = int(SquadMateOrder ESMO_HEAL)
    squad_member__orderPosition = float3()
    squad_member__orderUseEntity = INVALID_ENTITY_ID
    squad_member__isPersonalOrder = false
    request_squad_member_response(nearestTeammate.eid)
    ordered = true
  if !ordered
    if squad__numAliveMembers <= 1
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_HEAL}")
    else
      let text = isLeaderDowned ? "revive_order/no_revive_kits" : "heal_order/no_medkits"
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text=text]])
      send_order_cancel_bq(squad__leader, isLeaderDowned ? "no_revive_kits" : "no_medkits",
        "{SquadMateOrder ESMO_HEAL}")
  else
    query(nearestTeammate.eid) <| $ [es] (transform : float3x4)
      send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_HEAL}", transform[3], true)
  return ordered

[es(tag=server)]
def on_squad_mate_heal_order(evt : RequestSquadMateOrder; eid : EntityId; squad__leader : EntityId; squad__numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_HEAL
    order_heal(eid, squad__leader, squad__numAliveMembers)

[es(on_event=EventEntityDied, tag=server)]
def on_squad_mate_should_heal_died(evt : Event; eid : EntityId; squad_member__squad : EntityId; squad_member__orderType : int)
  if squad_member__orderType == int(SquadMateOrder ESMO_HEAL)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_HEAL}")
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
      order_heal(squad_member__squad, squad__leader, squad__numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_heal(act : UpdateStageInfoAct;
                       eid : EntityId;
                       squad_member__squad : EntityId;
                       var beh_tree : BehaviourTree&;
                       var squad_member__orderType : int&;
                       var squad_member__orderPosition : float3&;
                       var squad_member__orderUseEntity : EntityId&;
                       var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType == int(SquadMateOrder ESMO_HEAL)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      if beh_tree.blackBoard |> datablock_getInt("healRequester", 0) != int(uint(squad__leader))
        beh_tree.blackBoard |> set("healRequester", 0)
        reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
        reset_squad_mate_behaviour(eid)

[es(tag=server)]
def squad_mate_order_heal(evt : RequestSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == SquadMateOrder ESMO_HEAL
    if get_bool(squad__leader, "isDowned") ?? false
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadReviveMeOrder"]])
    else
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadHealMeOrder"]])

[es(tag=server, track=human_inventory__entityToUse)]
def squad_mate_order_heal_interrupted(evt : Event;
                                      eid : EntityId;
                                      human_inventory__entityToUse : EntityId;
                                      human_inventory__targetToUse : EntityId;
                                      squad_member__squad : EntityId;
                                      var beh_tree : BehaviourTree&;
                                      var squad_member__orderType : int&;
                                      var squad_member__orderPosition : float3&;
                                      var squad_member__orderUseEntity : EntityId&;
                                      var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType == int(SquadMateOrder ESMO_HEAL)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      if !human_inventory__entityToUse || human_inventory__targetToUse != squad__leader
        beh_tree.blackBoard |> set("healRequester", 0)
        reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
        reset_squad_mate_behaviour(eid)
