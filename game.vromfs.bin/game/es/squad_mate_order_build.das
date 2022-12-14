require ecs
require EnlistedWalkerai
require DagorDataBlock
require BehNodes
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require game.es.sound_net.sound_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require EnlistedBehTree
require game.es.squad_order_common

def order_build(squad_mate_eid, squad__leader, target_eid : EntityId; squad__numAliveMembers : int) : bool
  var ordered = false
  query(squad_mate_eid) <| $ [es] (beh_tree__isInTrainBeh : bool;
                                   beh_tree__data__orderReq : string;
                                   beh_tree__data__buildReq : string;
                                   transform : float3x4;
                                   var squad_member__orderType : int&;
                                   var squad_member__orderPosition : float3&;
                                   var squad_member__orderUseEntity : EntityId&;
                                   var beh_tree : BehaviourTree&;
                                   var beh_tree__refs__behaviour : das_string&;
                                   var beh_tree__refs__orderType : das_string&;
                                   var beh_tree__latencyLoadBlackBoard : Object?)
    if beh_tree__isInTrainBeh
      return

    beh_tree__refs__behaviour := beh_tree__data__orderReq
    beh_tree__refs__orderType := beh_tree__data__buildReq

    reload_squad_mate_beh_tree(squad_mate_eid)

    if beh_tree__latencyLoadBlackBoard != null
      *beh_tree__latencyLoadBlackBoard |> set("buildTarget", int(uint(target_eid)))
    beh_tree.blackBoard |> set("buildTarget", int(uint(target_eid)))

    squad_member__orderType = int(SquadMateOrder ESMO_BUILD)
    squad_member__orderPosition = float3()
    squad_member__orderUseEntity = target_eid
    request_squad_member_response(squad_mate_eid)
    send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_BUILD}", transform[3], true)
    ordered = true
  if !ordered
    if squad__numAliveMembers <= 1
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_BUILD}")
  return ordered

def squad_order_build(squad_eid, squad__leader, target_eid : EntityId; squad__numAliveMembers : int) : bool
  let isTargetPreview = has(target_eid, "builder_preview")
  let nearestTeammate = get_nearest_squad_mate_not_ordered(squad_eid, squad__leader) <| $(eid : EntityId)
    if !isTargetPreview
      return true
    var isSuitableForBuild = false
    query(eid) <| $ [es] (human_weap__gunEids : EidList;
                          squad_member__orderType : int;
                          squad_member__isPersonalOrder : bool)
      if !squad_member__isPersonalOrder && squad_member__orderType == int(SquadMateOrder ESMO_NO_ORDER)
        for gun_eid in human_weap__gunEids
          if has(gun_eid, "buildingTool")
            isSuitableForBuild = true
            break
    return isSuitableForBuild

  return order_build(nearestTeammate.eid, squad__leader, target_eid, squad__numAliveMembers)

def personal_order_build(squad_mate_eid, squad_member__squad, target_eid : EntityId) : bool
  var ordered = false
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
    ordered = order_build(squad_mate_eid, squad__leader, target_eid, squad__numAliveMembers)
  return ordered

[es(tag=server)]
def on_squad_mate_build_order(evt : RequestSquadMateOrder; eid : EntityId; squad__leader : EntityId; squad__numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_BUILD
    squad_order_build(eid, squad__leader, evt.orderUseEntity, squad__numAliveMembers)

[es(tag=server)]
def on_personal_squad_mate_build_order(evt : RequestPersonalSquadMateOrder;
                                       eid : EntityId;
                                       squad_member__squad : EntityId;
                                       var squad_member__isPersonalOrder : bool&)
  if evt.orderType == int(SquadMateOrder ESMO_BUILD)
    squad_member__isPersonalOrder = true
    personal_order_build(eid, squad_member__squad, evt.orderUseEntity)

[es(tag=server, no_order)]
def on_squad_mate_build(act : UpdateStageInfoAct;
                        eid : EntityId;
                        var beh_tree : BehaviourTree&;
                        var squad_member__orderType : int&;
                        var squad_member__orderPosition : float3&;
                        var squad_member__orderUseEntity : EntityId&;
                        var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType == int(SquadMateOrder ESMO_BUILD)
    let buildTargetEid = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("buildTarget", 0)))
    if !doesEntityExist(buildTargetEid) || buildTargetEid != squad_member__orderUseEntity
      beh_tree.blackBoard |> set("buildTarget", 0)
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      reset_squad_mate_behaviour(eid)

[es(on_event=EventEntityDied, tag=server)]
def on_build_order_squad_mate_died(evt : Event;
                                   eid : EntityId;
                                   squad_member__squad : EntityId;
                                   squad_member__orderType : int;
                                   squad_member__orderUseEntity : EntityId;
                                   squad_member__isPersonalOrder : bool)
  if squad_member__orderType == int(SquadMateOrder ESMO_BUILD)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_BUILD}")
    if !squad_member__isPersonalOrder
      query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
        squad_order_build(squad_member__squad, squad__leader, squad_member__orderUseEntity, squad__numAliveMembers)

[es(tag=server)]
def squad_build_order_speech(evt : RequestSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == SquadMateOrder ESMO_BUILD
    sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadBuildOrder"]])

[es(tag=server)]
def personal_squad_mate_build_order_speech(evt : RequestPersonalSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == int(SquadMateOrder ESMO_BUILD)
    sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadBuildOrder"]])
