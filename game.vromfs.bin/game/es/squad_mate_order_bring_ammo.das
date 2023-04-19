require ecs
require ecs.common
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
require HumanPhys
require DngWeapon
require DaWeaponProps
require player
require app
require DngNet
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require DngBehTree
require game.es.squad_order_common
require game.utils.net_utils

def order_ammo(squad_eid, squad__leader : EntityId; squad__numAliveMembers : int) : bool
  var ordered = false
  let nearestTeammate = get_nearest_squad_mate_for_order(squad_eid, squad__leader, SquadMateOrder ESMO_BRING_AMMO)
  if nearestTeammate.executeOrder
    return true
  query(nearestTeammate.eid) <| $ [es] (beh_tree__isInTrainBeh : bool;
                                        beh_tree__data__orderReq : string;
                                        beh_tree__data__ammoReq : string;
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
    beh_tree__refs__orderType := beh_tree__data__ammoReq

    reload_squad_mate_beh_tree(nearestTeammate.eid)

    if beh_tree__latencyLoadBlackBoard != null
      *beh_tree__latencyLoadBlackBoard |> set("ammoRequester", int(uint(squad__leader)))
    beh_tree.blackBoard |> set("ammoRequester", int(uint(squad__leader)))

    squad_member__orderType = int(SquadMateOrder ESMO_BRING_AMMO)
    squad_member__orderPosition = float3()
    squad_member__orderUseEntity = INVALID_ENTITY_ID
    squad_member__isPersonalOrder = false
    request_squad_member_response(nearestTeammate.eid, "squadBringAmmo")
    ordered = true
  if !ordered
    if squad__numAliveMembers <= 1
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_alive_squadmates", "{SquadMateOrder ESMO_BRING_AMMO}")
    else
      sendEvent(squad__leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_free_squadmates"]])
      send_order_cancel_bq(squad__leader, "no_free_squadmates", "{SquadMateOrder ESMO_BRING_AMMO}")
  else
    query(nearestTeammate.eid) <| $ [es] (transform : float3x4)
      send_squad_member_accept_order_bq(squad__leader, "{SquadMateOrder ESMO_BRING_AMMO}", transform[3], true)
  return ordered

[es(tag=server)]
def on_squad_mate_bring_ammo_order(evt : RequestSquadMateOrder; eid : EntityId; squad__leader : EntityId;
                                   squad__isLeaderNeedsAmmo : bool; squad__numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_BRING_AMMO && squad__isLeaderNeedsAmmo
    let requestAmmoAllowTime = get_float(squad__leader, "requestAmmoAllowTime") ?? 0f
    if requestAmmoAllowTime > get_sync_time()
      using() <| $(var data : Object)
        set(data, "time", int(requestAmmoAllowTime - get_sync_time()))
        send_net_event(squad__leader, [[CmdHeroLogExEvent event="squad_order_canceled", key="msg/canRequestIn", data=ecs_addr(data)]], target_entity_conn(squad__leader))
    else
      order_ammo(eid, squad__leader, squad__numAliveMembers)

[es(on_event=EventEntityDied, tag=server)]
def on_squad_mate_bring_ammo_died_es(evt : Event; eid : EntityId; squad_member__squad : EntityId; squad_member__orderType : int;
                                     squad__isLeaderNeedsAmmo : bool; squad__numAliveMembers : int)
  if squad_member__orderType == int(SquadMateOrder ESMO_BRING_AMMO) && squad__isLeaderNeedsAmmo
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_BRING_AMMO}")
    query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
      order_ammo(squad_member__squad, squad__leader, squad__numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_bring_ammo_es(act : UpdateStageInfoAct;
                                eid : EntityId;
                                squad_member__squad : EntityId;
                                var beh_tree : BehaviourTree&;
                                var squad_member__orderType : int&;
                                var squad_member__orderPosition : float3&;
                                var squad_member__orderUseEntity : EntityId&;
                                var squad_member__isPersonalOrder : bool&)
  if squad_member__orderType != int(SquadMateOrder ESMO_BRING_AMMO)
    return
  query(squad_member__squad) <| $ [es] (squad__leader : EntityId)
    if beh_tree.blackBoard |> datablock_getInt("ammoRequester", 0) != int(uint(squad__leader))
      reset_squad_mate_order(squad_member__orderType, squad_member__orderPosition, squad_member__orderUseEntity, squad_member__isPersonalOrder)
      reset_squad_mate_behaviour(eid)
      beh_tree.blackBoard |> set("ammoRequester", 0)

[es(tag=server)]
def squad_mate_order_bring_ammo_es(evt : RequestSquadMateOrder; squad__leader : EntityId)
  if evt.orderType == SquadMateOrder ESMO_BRING_AMMO
    sendEvent(squad__leader, [[CmdRequestHumanSpeech phrase="squadBringAmmoOrder"]])

def can_fit_another_magazine(item_container; ammo_props_id; max_magazines)
  var magazines = 0
  for itemEid in item_container
    query(itemEid) <| $ [es] (ammo_handler__id : int)
      if ammo_handler__id == ammo_props_id
        magazines++
    if magazines >= max_magazines
      break
  return magazines < max_magazines

struct LeaderAmmoState
  isNeedsAmmo : bool = false
  hasSpaceForMagazine : bool = true
  isCompatibleWeapon : bool = true

def apply_ammo_state(squad_eid : EntityId; state : LeaderAmmoState)
  query(squad_eid) <| $ [es] (var squad__isLeaderNeedsAmmo : bool&;
                              var order_ammo__hasSpaceForMagazine : bool&;
                              var order_ammo__isCompatibleWeapon : bool&)
    squad__isLeaderNeedsAmmo = state.isNeedsAmmo
    order_ammo__hasSpaceForMagazine = state.hasSpaceForMagazine
    order_ammo__isCompatibleWeapon = state.isCompatibleWeapon

def apply_ammo_state_server(squad_eid : EntityId; state : LeaderAmmoState)
  query(squad_eid) <| $ [es] (var squad__isLeaderNeedsAmmo : bool&)
    squad__isLeaderNeedsAmmo = state.isNeedsAmmo

def get_squad_leader_ammo_state(isInVehicle : bool;
                                human_weap__weapInfo : Array;
                                human_weap__gunEids : EidList;
                                human_weap__reserveAmmoPropIds : IntList;
                                itemContainer : EidList)
  var res = LeaderAmmoState()
  if isInVehicle
    res.isNeedsAmmo = false
    return res

  let slot = int(HUWeaponSlots EWS_PRIMARY)

  let gunEid = human_weap__gunEids[slot]
  if !gunEid
    res.isNeedsAmmo = false
    return res

  let reserveAmmoPropsId = human_weap__reserveAmmoPropIds[slot]

  query(gunEid) <| $ [es] (gun__ammo : int = 0;
                           gun__totalAmmo : int = 0;
                           gun__maxAmmo : int = 0;
                           gun__ammoHolderIds : IntList;
                           gun__requestAmmoThreshold : float = 0.10;
                           gun__propsId : int = -1;
                           gun__reloadable : bool = false)
    let weapInfo = get_ecs_object(human_weap__weapInfo[slot])
    let maxMagazines = get_int(weapInfo, "numReserveAmmo") ?? 0
    let reserveMaxShots = maxMagazines * gun__maxAmmo
    let shots = gun__totalAmmo + gun__ammo
    res.isCompatibleWeapon = find_index(gun__ammoHolderIds, reserveAmmoPropsId) >= 0 && gun__propsId >= 0 && gun__reloadable
    res.isNeedsAmmo = res.isCompatibleWeapon && float(shots) < gun__requestAmmoThreshold * float(reserveMaxShots)
    if !res.isNeedsAmmo
      return

    res.hasSpaceForMagazine = can_fit_another_magazine(itemContainer, reserveAmmoPropsId, maxMagazines - (gun__ammo > 0 ? 1 : 0))
    res.isNeedsAmmo &&= res.hasSpaceForMagazine
  return res


[es(tag=server, track=(human_weap__gunEids, isInVehicle, possessedByPlr))]
def squad_leader_needs_ammo_server(evt : Event;
                                   possessedByPlr : EntityId;
                                   isInVehicle : bool;
                                   squad_member__squad : EntityId;
                                   human_weap__weapInfo : Array;
                                   human_weap__gunEids : EidList;
                                   human_weap__reserveAmmoPropIds : IntList;
                                   itemContainer : EidList)
  if !!possessedByPlr
    let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap__weapInfo, human_weap__gunEids, human_weap__reserveAmmoPropIds, itemContainer)
    apply_ammo_state_server(squad_member__squad, ammoState)

[es(tag=server, track=(gun__ammo, gun__ammoHolderEid, gun__totalAmmo),
  REQUIRE=(gun__ammo, gun__ammoHolderEid, gun__totalAmmo))]
def squad_leader_gun_needs_ammo_server(evt : Event; gun__owner : EntityId)
  query(gun__owner) <| $ [es] (possessedByPlr : EntityId;
                               isInVehicle : bool;
                               squad_member__squad : EntityId;
                               human_weap__weapInfo : Array;
                               human_weap__gunEids : EidList;
                               human_weap__reserveAmmoPropIds : IntList;
                               itemContainer : EidList)
    if !!possessedByPlr
      let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap__weapInfo, human_weap__gunEids, human_weap__reserveAmmoPropIds, itemContainer)
      apply_ammo_state_server(squad_member__squad, ammoState)

[es(tag=gameClient, REQUIRE=hero, on_appear, track=(human_weap__gunEids, isInVehicle))]
def squad_leader_needs_ammo_client(evt : Event;
                                   isInVehicle : bool;
                                   squad_member__squad : EntityId;
                                   human_weap__weapInfo : Array;
                                   human_weap__gunEids : EidList;
                                   human_weap__reserveAmmoPropIds : IntList;
                                   itemContainer : EidList)
  let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap__weapInfo, human_weap__gunEids, human_weap__reserveAmmoPropIds, itemContainer)
  apply_ammo_state(squad_member__squad, ammoState)

[es(tag=gameClient, track=(gun__ammo, gun__ammoHolderEid, gun__totalAmmo),
  REQUIRE=(gun__ammo, gun__ammoHolderEid, gun__totalAmmo))]
def squad_leader_gun_needs_ammo_client(evt : Event; gun__owner : EntityId)
  query(gun__owner) <| $ [es(REQUIRE=hero)] (isInVehicle : bool;
                                             squad_member__squad : EntityId;
                                             human_weap__weapInfo : Array;
                                             human_weap__gunEids : EidList;
                                             human_weap__reserveAmmoPropIds : IntList;
                                             itemContainer : EidList)
    let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap__weapInfo, human_weap__gunEids, human_weap__reserveAmmoPropIds, itemContainer)
    apply_ammo_state(squad_member__squad, ammoState)
