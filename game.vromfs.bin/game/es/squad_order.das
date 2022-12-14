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
require enlisted.game.es.squad_behaviour_command_common
require game.es.squad_order_common

def squad_order_response(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId)
  ecs::query() <| $ [es(REQUIRE=squad_member)] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId)
    if squad_member__squad == squad_eid && eid != leader_eid
      request_squad_member_response(eid)

def squad_order_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; order_type : int) : bool
  if order_type == int(SquadOrder ESO_DEFEND_POINT)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadDefendOrder"]])
  elif order_type == int(SquadOrder ESO_FOLLOW_ME)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadRegroupOrder"]])
  elif order_type == int(SquadOrder ESO_USE_VEHICLE)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadUseVehicle"]])
  else
    return false
  squad_order_response(squad_eid, leader_eid)
  return true

def squad_formation_order_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; spread_type : SquadFormationSpread) : bool
  if spread_type == SquadFormationSpread ESFN_CLOSEST
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadClosestFormationOrder"]])
  elif spread_type == SquadFormationSpread ESFN_STANDARD
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadStandardFormationOrder"]])
  elif spread_type == SquadFormationSpread ESFN_WIDE
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadWideFormationOrder"]])
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

  reset_squad_behaviour_exclude_personal(eid)

[es(tag=server)]
def squad_formation_es(evt : RequestSquadFormation;
                       eid : ecs::EntityId;
                       squad__leader : ecs::EntityId;
                       squad__ownerPlayer : ecs::EntityId)
  ecs::query(squad__ownerPlayer) <| $ [es] (var squadFormationSpread : int&)
    squadFormationSpread = int(evt.spread)
    squad_formation_order_speech(eid, squad__leader, evt.spread)
    reset_squad_behaviour(eid)

def squad_behaviour_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; squad_behaviour : int)
  if squad_behaviour == int(SquadBehaviour ESB_AGRESSIVE)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadBehaviourAggressiveOrder"]])
  elif squad_behaviour == int(SquadBehaviour ESB_PASSIVE)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase="squadBehaviourPassiveOrder"]])
  squad_order_response(squad_eid, leader_eid)

[es(tag=server)]
def squad_behaviour_es(evt : RequestSquadBehaviour;
                       eid : ecs::EntityId;
                       squad__leader : ecs::EntityId;
                       var squad__squadBehaviour : int&)
  squad__squadBehaviour = evt.behaviour
  squad_behaviour_speech(eid, squad__leader, squad__squadBehaviour)

  reset_squad_behaviour_exclude_personal(eid)
