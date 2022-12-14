require enlisted.game.es.fortifications_build_common
require enlisted.events_enlisted
require game.es.vehicle.vehicle_seats_common
require game.events_game
require game.utils.team
require EnlistedPhysObj
require game.es.events
require DagorSystem
require DagorMath
require math.base
require RendInst
require PhysObj
require vehicle
require AnimV20
require EnlistedNet
require ecs

[es(on_appear, tag=server)]
def building_set_time_on_create_es(evt : Event; var building_destroy__timeToDestroy : float&; building_destroy__maxTimeToDestroy : float)
  building_destroy__timeToDestroy = building_destroy__maxTimeToDestroy

[es(tag=server, no_order)]
def building_reset_destruction_timer_es(info : UpdateStageInfoAct;
                                        building_destroy__maxTimeToDestroy : float;
                                        building_destroy__timeToResetDestructionTimer : float;
                                        var building_destroy__lastDamageAtTime : float&;
                                        var building_destroy__timeToDestroy : float&)
  if building_destroy__lastDamageAtTime == -1.f
    return
  if info.curTime - building_destroy__lastDamageAtTime > building_destroy__timeToResetDestructionTimer
    building_destroy__timeToDestroy = building_destroy__maxTimeToDestroy
    building_destroy__lastDamageAtTime = -1.f

def has_attached_soldier(building_eid : EntityId)
  var isAttached = false
  let isBuildingGun = query(building_eid) <| $ [es(REQUIRE=stationary_gun)] (gun__owner : EntityId)
    isAttached = !!gun__owner
  if !isBuildingGun
    find_query() <| $ [es(REQUIRE=stationary_gun)] (dependsOnBuildingEid : EntityId; gun__owner : EntityId)
      if dependsOnBuildingEid == building_eid
        isAttached = !!gun__owner
        return true
      return false
  return isAttached

[es(tag=server, no_order)]
def destroyable_fortification_building_object(info : UpdateStageInfoAct;
                                              eid : EntityId;
                                              building_action__target : EntityId;
                                              transform : float3x4;
                                              enter_vehicle__atTime : float;
                                              human_use_object__useDist : float;
                                              human_weap__gunEids : ecs::EidList;
                                              building_action__updateInterval : float;
                                              entity_mods__timeToBuildMul = 1.0;
                                              var building_action__lastActionAtTime : float&)
  if !building_action__target || building_action__lastActionAtTime + building_action__updateInterval > info.curTime
    return
  if building_action__lastActionAtTime == -1.0
    building_action__lastActionAtTime = info.curTime
    return
  let operatorEid = eid
  if enter_vehicle__atTime > 0.f
    send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
  let operatorPos = transform[3]
  let target = building_action__target
  query(target) <| $ [es(REQUIRE_NOT=undestroyableBuilding)] (eid : EntityId;
                                                              transform : float3x4;
                                                              var activated : bool?;
                                                              var building_destroy__operator : EntityId&;
                                                              var building_destroy__timeToDestroy : float&;
                                                              var building_destroy__lastDamageAtTime : float&;
                                                              building_destroy__distanceVerifyThreshold : float)
    if length_sq(transform[3] - operatorPos) > square(human_use_object__useDist + building_destroy__distanceVerifyThreshold)
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    let buildingSpeedMul = get_engineer_building_speed_mul(human_weap__gunEids)
    building_destroy__timeToDestroy -= (info.curTime - building_action__lastActionAtTime) * buildingSpeedMul * entity_mods__timeToBuildMul
    building_destroy__lastDamageAtTime = info.curTime
    building_action__lastActionAtTime = info.curTime
    if building_destroy__timeToDestroy < 0.f
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      if is_vehicle_with_alive_crew(eid) || has_attached_soldier(eid)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_destroy_with_crew", text="building_blocked_destroy_with_crew"]])
        return
      if activated != null
        *activated = false
      building_destroy__operator = operatorEid
      sendEventImmediate(eid, [[EventOnDestroyBuilding]])
      destroyEntity(eid)

[es(tag=server)]
def dismantle_preview(evt : EventDismantleBuilding; eid : EntityId; isAlive : bool; isDowned : bool;
                      team = TEAM_UNASSIGNED;
                      squad_member__playerEid = INVALID_ENTITY_ID;
                      human_weap__mortarMode : bool = false;
                      human_weap__radioMode : bool = false)
  if !isAlive || isDowned || human_weap__mortarMode || human_weap__radioMode
    return
  if !is_player_can_destroy_building(squad_member__playerEid, team, evt.target)
    sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_destroy_only_by_owner", text="building_blocked_destroy_only_by_owner"]])
    return
  if is_vehicle_with_alive_crew(evt.target) || has_attached_soldier(evt.target)
    sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_destroy_with_crew", text="building_blocked_destroy_with_crew"]])
    return
  if has(evt.target, "builder_server_preview")
    if !!get_player_eid_interacting_building(evt.target, eid)
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_destroy_during_build", text="building_blocked_destroy_during_build"]])
      return
    destroyEntity(evt.target)
  else
    send_net_event(eid, [[EventSetBuildingTarget target=evt.target]])

[es(tag=server, REQUIRE_NOT=phys_obj_net_phys)]
def building_deattached_from_ri_es(evt : EventRendinstDestroyed;
                                   eid : EntityId;
                                   build_attach__riexHandle : riex_handle_t)
  if build_attach__riexHandle != RIEX_HANDLE_NULL && evt.riexHandle == build_attach__riexHandle
    destroyEntity(eid)

[es(tag=server)]
def building_updatepos_on_ri_destroyed_es(evt : EventRendinstDestroyed;
                                          build_attach__riexHandle : riex_handle_t;
                                          var animchar__updatable : bool&;
                                          var phys_obj_net_phys : PhysObjActor)
  if build_attach__riexHandle != RIEX_HANDLE_NULL && evt.riexHandle == build_attach__riexHandle
    animchar__updatable = true
    phys_obj_net_phys.phys |> wakeUp()