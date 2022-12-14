require ecs
require EnlistedWalkerai
require DagorDataBlock
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require game.es.sound_net.sound_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require EnlistedBehTree
require game.es.squad_order_common

[es(tag=server)]
def on_personal_squadmate_defend_order(evt : RequestPersonalSquadMateOrder;
                                       eid : EntityId;
                                       squad_member__squad : EntityId;
                                       transform : float3x4;
                                       beh_tree__isInTrainBeh : bool;
                                       beh_tree__data__personalOrder : string;
                                       var squad_member__orderType : int&;
                                       var squad_member__orderPosition : float3&;
                                       var squad_member__orderUseEntity : EntityId&;
                                       var squad_member__isPersonalOrder : bool&;
                                       var beh_tree__refs__behaviour : das_string&)
  if evt.orderType == int(SquadMateOrder ESMO_DEFEND_POINT) && !beh_tree__isInTrainBeh
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      beh_tree__refs__behaviour := beh_tree__data__personalOrder

      reload_squad_mate_beh_tree(eid)

      squad_member__orderType = int(SquadMateOrder ESMO_DEFEND_POINT)
      squad_member__orderPosition = evt.orderPosition
      squad_member__orderUseEntity = evt.orderUseEntity
      squad_member__isPersonalOrder = true
      sendEvent(eid, [[CmdRequestHumanSpeech phrase="confirmResponseDelayed"]])
      send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_DEFEND_POINT}", transform[3], true)

[es(tag=server)]
def squadmate_defend_order_speech(evt : RequestPersonalSquadMateOrder;
                                  eid : EntityId;
                                  squad_member__squad : EntityId)
  if evt.orderType == int(SquadMateOrder ESMO_DEFEND_POINT)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadDefendOrder"]])
      request_squad_member_response(eid, "confirm")
