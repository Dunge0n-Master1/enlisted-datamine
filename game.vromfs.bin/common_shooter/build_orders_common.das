module build_orders_common shared
require enlisted.game.es.enlisted_squad_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require EnlistedBehTree
require game.es.squad_order_common
require ecs
require BehNodes
require DagorDataBlock
require danetlibs.native_dasevents.main.native_events


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
  if !ordered && squad__numAliveMembers <= 1
    sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
    send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_BUILD}")
  return ordered

def personal_order_build(squad_mate_eid, squad_member__squad, target_eid : EntityId) : bool
  var ordered = false
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
    ordered = order_build(squad_mate_eid, squad__leader, target_eid, squad__numAliveMembers)
  return ordered
