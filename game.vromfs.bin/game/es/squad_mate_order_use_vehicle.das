require ecs
require EnlistedWalkerai
require DagorDataBlock
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require game.es.sound_net.sound_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common

[es(tag=server)]
def on_personal_squadmate_use_vehicle_order(evt : RequestPersonalSquadMateOrder;
                                            eid : EntityId;
                                            squad_member__squad : EntityId;
                                            transform : float3x4;
                                            var squad_member__orderType : int&;
                                            var squad_member__orderPosition : float3&;
                                            var squad_member__orderUseEntity : EntityId&;
                                            var squad_member__isPersonalOrder : bool&)
  if evt.orderType == int(SquadMateOrder ESMO_USE_VEHICLE)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      squad_member__orderType = int(SquadMateOrder ESMO_USE_VEHICLE)
      squad_member__orderPosition = evt.orderPosition
      squad_member__orderUseEntity = evt.orderUseEntity
      squad_member__isPersonalOrder = true
      sendEvent(eid, [[CmdRequestHumanSpeech phrase="confirmResponseDelayed", importance=1.]])
      send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_USE_VEHICLE}", transform[3], true)

[es(tag=server)]
def squad_use_vehicle_order_speech(evt : RequestPersonalSquadMateOrder; eid, squad_member__squad : EntityId)
  if evt.orderType == int(SquadMateOrder ESMO_USE_VEHICLE)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadUseVehicle", importance=1.]])
      request_squad_member_response(eid, "confirm")
