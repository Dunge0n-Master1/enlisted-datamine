require ecs
require EnlistedWalkerai
require DagorDataBlock
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require human_sounds_net.modules.human_sounds_net_events
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require game.es.vehicle.vehicle_seats_common
require BehNodes
require EnlistedBehTree
require game.es.squad_order_common

[es(tag=server)]
def on_personal_squadmate_use_vehicle_order(evt : RequestPersonalSquadMateOrder;
                                            eid : EntityId;
                                            isInVehicle : bool;
                                            squad_member__squad : EntityId;
                                            transform : float3x4;
                                            var squad_member__orderType : int&;
                                            var squad_member__orderPosition : float3&;
                                            var squad_member__orderUseEntity : EntityId&;
                                            var squad_member__isPersonalOrder : bool&)
  var hasSeatInVehicle = false
  query(evt.orderUseEntity) <| $ [es] (vehicle_seats__seatEids : EidList)
    hasSeatInVehicle = find_vehicle_seat_for_bot(vehicle_seats__seatEids) >= 0

  if evt.orderType == int(SquadMateOrder ESMO_USE_VEHICLE) && (isInVehicle || hasSeatInVehicle)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      squad_member__orderType = int(SquadMateOrder ESMO_USE_VEHICLE)
      squad_member__orderPosition = evt.orderPosition
      squad_member__orderUseEntity = evt.orderUseEntity
      squad_member__isPersonalOrder = true
      sendEvent(eid, [[CmdRequestHumanSpeech phrase="confirmResponseDelayed"]])
      send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_USE_VEHICLE}", transform[3], true)

[es(tag=server)]
def squad_use_vehicle_order_speech(evt : RequestPersonalSquadMateOrder; eid, squad_member__squad : EntityId)
  if evt.orderType == int(SquadMateOrder ESMO_USE_VEHICLE)
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadUseVehicle"]])
      request_squad_member_response(eid, "confirm")

[es(tag=server, no_order)]
def on_squad_leader_out_vehicle_es(act : UpdateStageInfoAct;
                                   squad__leader : EntityId;
                                   squad__allMembers : EidList;
                                   squad__orderType : int;
                                   squad__orderUseEntity : EntityId)
  var leaderIsInVehicle = true
  query(squad__leader) <| $ [es] (isInVehicle : bool) // default is true if leader is invalid, do not leave the vehicle
    leaderIsInVehicle = isInVehicle

  if leaderIsInVehicle
    return

  for squadMemberEid in squad__allMembers
    if squad__leader == squadMemberEid
      continue

    query(squadMemberEid) <| $ [es] (isInVehicle : bool;
                                     human_anim__vehicleSelected : EntityId;
                                     squad_member__orderType : int;
                                     squad_member__orderUseEntity : EntityId;
                                     beh_tree__data__orderReq : string;
                                     beh_tree__data__useVehicleReq : string;
                                     beh_tree__data__vehicleBeh : string;
                                     beh_tree__isInTrainBeh : bool;
                                     beh_tree__shouldUseVehicle : bool;
                                     var beh_tree__shouldUseVehicleResetTrigger : bool&;
                                     var beh_tree__orderIsInVehicle : bool&;
                                     var beh_tree__orderShouldUseVehicle : bool&;
                                     var beh_tree__refs__behaviour : das_string&;
                                     var beh_tree__refs__orderType : das_string&;
                                     var beh_tree : BehaviourTree&;
                                     var beh_tree__latencyLoadBlackBoard : Object?)
      if beh_tree__shouldUseVehicle
        if squad_member__orderType != int(SquadMateOrder ESMO_USE_VEHICLE)
          reset_squad_mate_order(squadMemberEid)
          reset_squad_mate_behaviour(squadMemberEid)
        else
          reset_squad_mate_behaviour(squadMemberEid)

      let vehicleEid = squad__orderType == int(SquadOrder ESO_USE_VEHICLE) ? squad__orderUseEntity : squad_member__orderUseEntity

      var hasSeatInVehicle = false
      query(vehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList)
        hasSeatInVehicle = find_vehicle_seat_for_bot(vehicle_seats__seatEids) >= 0

      if ((squad__orderType == int(SquadOrder ESO_USE_VEHICLE) && squad_member__orderType == int(SquadMateOrder ESMO_NO_ORDER)) ||
           squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE)) && !beh_tree__isInTrainBeh
        if !isInVehicle && !hasSeatInVehicle
          return

        if isInVehicle && vehicleEid != human_anim__vehicleSelected
          query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
            kick_from_vehicle(squadMemberEid, human_anim__vehicleSelected, vehicle_seats__seatEids)
          return

        if !beh_tree__orderShouldUseVehicle
          beh_tree__orderShouldUseVehicle  = true
          beh_tree__shouldUseVehicleResetTrigger = true

          if !isInVehicle
            beh_tree__refs__behaviour := beh_tree__data__orderReq
            beh_tree__refs__orderType := beh_tree__data__useVehicleReq
          else
            beh_tree__orderIsInVehicle     = true
            beh_tree__refs__behaviour := beh_tree__data__vehicleBeh

          EnlistedBehTree::load_beh_tree_from_ecs(squadMemberEid)
          if beh_tree__latencyLoadBlackBoard != null
            *beh_tree__latencyLoadBlackBoard |> set("vehicleEid", int(uint(vehicleEid)))
          beh_tree.blackBoard |> set("vehicleEid", int(uint(vehicleEid)))

        elif isInVehicle && !beh_tree__orderIsInVehicle
          beh_tree__orderIsInVehicle     = true
          beh_tree__refs__behaviour := beh_tree__data__vehicleBeh

          EnlistedBehTree::load_beh_tree_from_ecs(squadMemberEid)

          if beh_tree__latencyLoadBlackBoard != null
            *beh_tree__latencyLoadBlackBoard |> set("vehicleEid", int(uint(vehicleEid)))
          beh_tree.blackBoard |> set("vehicleEid", int(uint(vehicleEid)))
      else
        beh_tree__orderIsInVehicle      = false
        beh_tree__orderShouldUseVehicle = false

        if isInVehicle
          query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
            kick_from_vehicle(squadMemberEid, human_anim__vehicleSelected, vehicle_seats__seatEids)
require DagorSystem
[es(tag=server, no_order)]
def on_squad_leader_in_vehicle_es(act : UpdateStageInfoAct;
                                  squad__leader : EntityId;
                                  squad__allMembers : EidList;
                                  squad__orderUseEntity : EntityId;
                                  squad__orderType : int)
  var leaderIsInVehicle = false
  var leaderVehicleEid  = INVALID_ENTITY_ID
  query(squad__leader) <| $ [es] (isInVehicle : bool;
                                  human_anim__vehicleSelected : EntityId)
    leaderIsInVehicle = isInVehicle
    leaderVehicleEid  = human_anim__vehicleSelected

  if !leaderIsInVehicle
    return

  if squad__orderType == int(SquadOrder ESO_DEFEND_POINT)
    return

  for squadMemberEid in squad__allMembers
    if squad__leader == squadMemberEid
      continue

    query(squadMemberEid) <| $ [es] (squad_member__orderType : int;
                                     beh_tree__shouldUseVehicle : bool)
      if squad_member__orderType == int(SquadMateOrder ESMO_USE_VEHICLE) && beh_tree__shouldUseVehicle
        return

      let isInResetableOrder = (squad_member__orderType != int(SquadMateOrder ESMO_NO_ORDER) &&
                                squad_member__orderType != int(SquadMateOrder ESMO_DEFEND_POINT) &&
                                squad_member__orderType != int(SquadMateOrder ESMO_USE_VEHICLE))

      if isInResetableOrder
        reset_squad_mate_order(squadMemberEid)
        reset_squad_mate_behaviour(squadMemberEid)

  var hasSeatInVehicle = false
  query(leaderVehicleEid) <| $ [es] (vehicle_seats__seatEids : EidList)
    hasSeatInVehicle = find_vehicle_seat_for_bot(vehicle_seats__seatEids) >= 0

  for squadMemberEid in squad__allMembers
    if squad__leader == squadMemberEid
      continue

    query(squadMemberEid) <| $ [es] (isInVehicle : bool;
                                     human_anim__vehicleSelected : EntityId;
                                     beh_tree__data__orderReq : string;
                                     beh_tree__data__useVehicleReq : string;
                                     beh_tree__data__vehicleBeh : string;
                                     beh_tree__isInTrainBeh : bool;
                                     squad_member__orderType : int;
                                     squad_member__orderUseEntity : EntityId;
                                     var beh_tree__isInVehicleResetTrigger : bool&;
                                     var beh_tree__isInVehicle : bool&;
                                     var beh_tree__shouldUseVehicleResetTrigger : bool&;
                                     var beh_tree__shouldUseVehicle : bool&;
                                     var beh_tree__refs__behaviour : das_string&;
                                     var beh_tree__refs__orderType : das_string&;
                                     var beh_tree : BehaviourTree&;
                                     var beh_tree__latencyLoadBlackBoard : Object?)
      if squad_member__orderType != int(SquadMateOrder ESMO_NO_ORDER)
        return

      let isInLeaderVehicle = isInVehicle && human_anim__vehicleSelected == leaderVehicleEid
      let vehicleEid = squad__orderType == int(SquadOrder ESO_USE_VEHICLE) ? squad__orderUseEntity : squad_member__orderUseEntity

      if !isInLeaderVehicle && (isInVehicle && vehicleEid != human_anim__vehicleSelected)
        query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
          kick_from_vehicle(squadMemberEid, human_anim__vehicleSelected, vehicle_seats__seatEids)
        return

      if (!isInLeaderVehicle && !hasSeatInVehicle) || beh_tree__isInTrainBeh
        return

      if !beh_tree__shouldUseVehicle
        beh_tree__shouldUseVehicleResetTrigger = true
        beh_tree__shouldUseVehicle = true

        if !isInLeaderVehicle
          if isInVehicle && vehicleEid == human_anim__vehicleSelected
            beh_tree__isInVehicleResetTrigger = true
            beh_tree__isInVehicle = true

            beh_tree__refs__behaviour := beh_tree__data__vehicleBeh
          else
            beh_tree__refs__behaviour := beh_tree__data__orderReq
            beh_tree__refs__orderType := beh_tree__data__useVehicleReq
        else
          beh_tree__isInVehicleResetTrigger = true
          beh_tree__isInVehicle = true

          beh_tree__refs__behaviour := beh_tree__data__vehicleBeh

        EnlistedBehTree::load_beh_tree_from_ecs(squadMemberEid)

        if beh_tree__latencyLoadBlackBoard != null
          *beh_tree__latencyLoadBlackBoard |> set("vehicleEid", int(uint(leaderVehicleEid)))
        beh_tree.blackBoard |> set("vehicleEid", int(uint(leaderVehicleEid)))

      elif isInLeaderVehicle && !beh_tree__isInVehicle
        beh_tree__isInVehicleResetTrigger = true
        beh_tree__isInVehicle = true

        beh_tree__refs__behaviour := beh_tree__data__vehicleBeh

        EnlistedBehTree::load_beh_tree_from_ecs(squadMemberEid)
        if beh_tree__latencyLoadBlackBoard != null
          *beh_tree__latencyLoadBlackBoard |> set("vehicleEid", int(uint(leaderVehicleEid)))
        beh_tree.blackBoard |> set("vehicleEid", int(uint(leaderVehicleEid)))

[es(tag=server, track=beh_tree__shouldUseVehicleResetTrigger)]
def on_squad_mate_use_vehicle_es(evt : Event;
                                 eid : EntityId;
                                 beh_tree__shouldUseVehicleResetTrigger : bool;
                                 var beh_tree__isInVehicle : bool&;
                                 var beh_tree__shouldUseVehicle : bool&)
  if beh_tree__shouldUseVehicleResetTrigger
    return

  beh_tree__shouldUseVehicle = false
  beh_tree__isInVehicle      = false

  reset_squad_mate_order(eid)
  reset_squad_mate_behaviour(eid)

[es(tag=server, track=beh_tree__isInVehicleResetTrigger)]
def on_squad_mate_order_use_vehicle_es(evt : Event;
                                       eid : EntityId;
                                       beh_tree__isInVehicleResetTrigger : bool;
                                       var beh_tree__orderIsInVehicle : bool&;
                                       var beh_tree__orderShouldUseVehicle : bool&)
  if beh_tree__isInVehicleResetTrigger
    return

  beh_tree__orderIsInVehicle      = false
  beh_tree__orderShouldUseVehicle = false

  reset_squad_mate_order(eid)
  reset_squad_mate_behaviour(eid)
