require ecs
require EnlistedWalkerai
require DagorDataBlock
require BehNodes
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require human_sounds_net.modules.human_sounds_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require enlisted.game.es.bomb_site_common
require EnlistedBehTree
require game.es.squad_order_common

def order_plant(squadmate_eid : EntityId;
                squad__leader : EntityId;
                order_position : float3;
                order_use_entity : EntityId;
                squad__numAliveMembers : int) : bool
  var ordered = false
  query(squadmate_eid) <| $ [es] (transform : float3x4;
                                  beh_tree__isInTrainBeh : bool;
                                  beh_tree__data__orderReq : string;
                                  beh_tree__data__plantBombReq : string;
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
    beh_tree__refs__orderType := beh_tree__data__plantBombReq

    reload_squad_mate_beh_tree(squadmate_eid)

    if beh_tree__latencyLoadBlackBoard != null
      *beh_tree__latencyLoadBlackBoard |> set("bombSiteEid", int(uint(order_use_entity)))
      *beh_tree__latencyLoadBlackBoard |> set("bombSitePos", order_position)
    beh_tree.blackBoard |> set("bombSiteEid", int(uint(order_use_entity)))
    beh_tree.blackBoard |> set("bombSitePos", order_position)

    squad_member__orderType = int(SquadMateOrder ESMO_PLANT_BOMB)
    squad_member__orderPosition = order_position
    squad_member__orderUseEntity = order_use_entity
    request_squad_member_response(squadmate_eid)
    send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_PLANT_BOMB}", transform[3], true)
    ordered = true

  if !ordered
    if squad__numAliveMembers <= 1
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_PLANT_BOMB}")

  return ordered

def squad_order_plant(squad_eid : EntityId;
                      squad__leader : EntityId;
                      order_position : float3;
                      order_use_entity : EntityId;
                      squad__numAliveMembers : int) : bool
  let nearestTeammate = get_nearest_squad_mate_not_ordered(squad_eid, squad__leader) <| $(eid : EntityId)
    var canPlantBomb = can_plant_bomb(order_use_entity, eid)
    query(eid) <| $ [es] (squad_member__isPersonalOrder : bool)
      if squad_member__isPersonalOrder
        canPlantBomb = false
    return canPlantBomb
  return order_plant(nearestTeammate.eid, squad__leader, order_position, order_use_entity, squad__numAliveMembers)

def personal_order_plant(squadmate_eid : EntityId;
                         squad_member__squad : EntityId;
                         orderPosition : float3;
                         orderUseEntity : EntityId) : bool
  var ordered = false
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
    ordered = order_plant(squadmate_eid, squad__leader, orderPosition, orderUseEntity, squad__numAliveMembers)
  return ordered

[es(tag=server)]
def on_squadmate_plant_order(evt : RequestSquadMateOrder;
                             eid : EntityId;
                             squad__leader : EntityId;
                             squad__numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_PLANT_BOMB
    squad_order_plant(eid, squad__leader, evt.orderPosition, evt.orderUseEntity, squad__numAliveMembers)

[es(tag=server)]
def on_personal_squadmate_plant_order(evt : RequestPersonalSquadMateOrder;
                                      eid : EntityId;
                                      squad_member__squad : EntityId;
                                      var squad_member__isPersonalOrder : bool&)
  if evt.orderType == int(SquadMateOrder ESMO_PLANT_BOMB) && can_plant_bomb(evt.orderUseEntity, eid)
    squad_member__isPersonalOrder = true
    personal_order_plant(eid, squad_member__squad, evt.orderPosition, evt.orderUseEntity)

[es(tag=server, no_order)]
def on_squadmate_plant(act : UpdateStageInfoAct;
                       eid : EntityId;
                       var beh_tree : BehaviourTree&;
                       var squad_member__orderType : int&;
                       var squad_member__orderPosition : float3&;
                       var squad_member__orderUseEntity : EntityId&;
                       var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType == int(SquadMateOrder ESMO_PLANT_BOMB)
    let bombSiteEid = EntityId(uint(beh_tree.blackBoard |> datablock_getInt("bombSiteEid", 0)))
    if bombSiteEid != squad_member__orderUseEntity || !can_plant_bomb(bombSiteEid, eid)
      beh_tree.blackBoard |> set("bombSiteEid", 0)
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      reset_squad_mate_behaviour(eid)

[es(tag=server, on_event=EventEntityDied)]
def on_plant_order_squadmate_died(evt : Event;
                                  eid : EntityId;
                                  squad_member__squad : EntityId;
                                  squad_member__orderType : int;
                                  squad_member__orderPosition : float3;
                                  squad_member__orderUseEntity : EntityId;
                                  squad_member__isPersonalOrder : bool)
  if squad_member__orderType == int(SquadMateOrder ESMO_PLANT_BOMB)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_PLANT_BOMB}")
    if !squad_member__isPersonalOrder
      query(squad_member__squad) <| $ [es] (squad__leader : EntityId; squad__numAliveMembers : int)
        squad_order_plant(squad_member__squad, squad__leader, squad_member__orderPosition, squad_member__orderUseEntity, squad__numAliveMembers)

[es(tag=server)]
def squad_plant_order_speech(evt : RequestSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == SquadMateOrder ESMO_PLANT_BOMB
    sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadPlantOrder"]])

[es(tag=server)]
def personal_squadmate_plant_order_speech(evt : RequestPersonalSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == int(SquadMateOrder ESMO_PLANT_BOMB)
    sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadPlantOrder"]])
