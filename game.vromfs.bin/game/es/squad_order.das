require ecs
require ecs.common
require EnlistedWalkerai
require DagorRandom
require DagorDataBlock
require BehNodes
require EnlistedWeapon
require game.es.events
require game.es.vehicle.vehicle_events
require game.es.sound_net.sound_net_events
require enlisted.events_enlisted
require player
require math
require enlisted.game.es.enlisted_squad_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common

def squad_order_response(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId)
  ecs::query() <| $ [es(REQUIRE=squad_member)] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId)
    if squad_member__squad == squad_eid && eid != leader_eid
      request_squad_member_response(eid)

def squad_order_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; order_type : int) : bool
  if order_type == int(SquadOrder ESO_DEFEND_POINT)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadDefendOrder", importance=1.]])
  elif order_type == int(SquadOrder ESO_FOLLOW_ME)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadRegroupOrder", importance=1.]])
  elif order_type == int(SquadOrder ESO_USE_VEHICLE)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadUseVehicle", importance=1.]])
  else
    return false
  squad_order_response(squad_eid, leader_eid)
  return true

def squad_formation_order_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; spread_type : SquadFormationSpread) : bool
  if spread_type == SquadFormationSpread ESFN_CLOSEST
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadClosestFormationOrder", importance=1.]])
  elif spread_type == SquadFormationSpread ESFN_STANDARD
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadStandardFormationOrder", importance=1.]])
  elif spread_type == SquadFormationSpread ESFN_WIDE
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadWideFormationOrder", importance=1.]])
  else
    return false
  squad_order_response(squad_eid, leader_eid)
  return true

[es(tag=server)]
def squad_order_es(
                   evt : RequestSquadOrder;
                   eid : ecs::EntityId;
                   squad__leader : ecs::EntityId;
                   var squad__orderType : int&;
                   var squad__orderPosition : float3&;
                   var squad__orderUseEntity : ecs::EntityId&)
  squad__orderType = int(evt.orderType)
  squad__orderPosition = evt.orderPosition
  squad__orderUseEntity = evt.orderUseEntity

  squad_order_speech(eid, squad__leader, squad__orderType)
  send_squad_member_accept_order_bq(squad__leader, "{squad__orderType}")

[es(tag=server)]
def squad_formation_es(evt : RequestSquadFormation;
                       eid : ecs::EntityId;
                       squad__leader : ecs::EntityId;
                       squad__ownerPlayer : ecs::EntityId)
  ecs::query(squad__ownerPlayer) <| $ [es] (var squadFormationSpread : int&)
    squadFormationSpread = int(evt.spread)
    squad_formation_order_speech(eid, squad__leader, evt.spread)

def squad_behaviour_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId)
  squad_order_response(squad_eid, leader_eid)

[es(tag=server)]
def squad_behaviour_es(evt : RequestSquadBehaviour;
                       eid : ecs::EntityId;
                       squad__leader : ecs::EntityId;
                       var squad__squadBehaviour : int&)
  squad__squadBehaviour = evt.behaviour
  squad_behaviour_speech(eid, squad__leader)

[es(tag=server, REQUIRE=human)]
def reset_squad_order_on_vehicle_enter(evt : EventEnterVehicle;
                                       eid : EntityId;
                                       squad_member__squad : EntityId)
  if evt.enter
    query(squad_member__squad) <| $ [es] (squad__allMembers : EidList;
                                          squad__leader : EntityId)
      if squad__leader != eid
        return

      for squarMemberEid in squad__allMembers
        if squarMemberEid == squad__leader
          continue

        query(squarMemberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (isInVehicle : bool;
                                                                 vehicle__lastEid : EntityId;
                                                                 var squad_member__orderType : int&;
                                                                 var squad_member__orderPosition : float3&;
                                                                 var squad_member__orderUseEntity : EntityId&;
                                                                 var squad_member__isPersonalOrder : bool&)
          let isBotOrderedToOccupyEnteredVehicle = squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE) && squad_member__orderUseEntity == evt.vehicle
          if (isInVehicle || isBotOrderedToOccupyEnteredVehicle) && vehicle__lastEid == evt.vehicle
            squad_member__orderType = int(SquadMateOrder ESMO_NO_ORDER)
            squad_member__orderPosition = float3()
            squad_member__orderUseEntity = INVALID_ENTITY_ID
            squad_member__isPersonalOrder = false