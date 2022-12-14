require enlisted.game.es.fortifications_build_common
require enlisted.events_enlisted
require RendInst
require danetlibs.native_dasevents.main.native_events
require game.utils.team
require DagorMath
require math.base
require CollRes
require Dacoll
require ecs
require EnlistedNet
require player

[es(tag=server, no_order, REQUIRE=buildingRestrictedZone)]
def building_fortification_destroy_on_distance(info : UpdateStageInfoAct;
                                               transform aka restricted_zone_transform : float3x4;
                                               building_restricted_zone__updateInterval : float;
                                               building_restricted_zone__maxAngle : float = -1.;
                                               building_restricted_zone__minDistanceForTeamOffense : float = -1.;
                                               building_restricted_zone__minDistanceForTeamDefense : float = -1.;
                                               capzone__trainOffenseTeam : int = TEAM_UNASSIGNED;
                                               var building_restricted_zone__nextUpdateAt : float&)
  if info.curTime < building_restricted_zone__nextUpdateAt
    return
  building_restricted_zone__nextUpdateAt = info.curTime + building_restricted_zone__updateInterval

  query() <| $ [es(REQUIRE=(buildByPlayer, buildTypeId))] (eid : EntityId; transform : float3x4; builder_info__team : int)
    if is_in_building_restricted_zone_sector(transform[3],
                                             builder_info__team,
                                             restricted_zone_transform,
                                             building_restricted_zone__maxAngle,
                                             building_restricted_zone__minDistanceForTeamOffense,
                                             building_restricted_zone__minDistanceForTeamDefense,
                                             capzone__trainOffenseTeam)
      destroyEntity(eid)

[es(on_event=EventEntityDestroyed, tag=server, REQUIRE=buildByPlayer)]
def building_target_destroyed(evt : Event; eid : EntityId)
  let buildingEid = eid
  query() <| $ [es] (eid : EntityId; building_action__target : EntityId)
    if building_action__target == buildingEid
      send_net_event(eid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])

[es(tag=server, no_order)]
def building_fortification_building_object(info : UpdateStageInfoAct;
                                           eid : EntityId;
                                           building_action__target : EntityId;
                                           transform : float3x4;
                                           team : int;
                                           human_use_object__useDist : float;
                                           human_weap__gunEids : ecs::EidList;
                                           var building_action__lastActionAtTime : float&;
                                           building_action__updateInterval : float;
                                           entity_mods__timeToBuildMul = 1.0)
  if !building_action__target || building_action__lastActionAtTime + building_action__updateInterval > info.curTime
    return
  if building_action__lastActionAtTime == -1.0
    building_action__lastActionAtTime = info.curTime
    return
  let operatorEid = eid
  let operatorPos = transform[3]
  query(building_action__target) <| $ [es] (eid : EntityId;
                                            transform : float3x4;
                                            var building_builder__timeToBuild : float&;
                                            building_builder__maxTimeToBuild : float;
                                            buildingBoxMin : float3;
                                            buildingBoxMax : float3;
                                            instantiateTemplate : string;
                                            additionalBuildingTemplate : string;
                                            buildingRadius : float;
                                            buildingSoundTag : string;
                                            buildByPlayer : EntityId;
                                            buildByEngineerEid : EntityId;
                                            builder_info__squadEid : EntityId;
                                            builder_info__guid : string;
                                            builder_info__team : int;
                                            buildTypeId : int;
                                            previewTeam : int;
                                            build_attach__riexHandle : riex_handle_t;
                                            savePreviewTeam = false;
                                            building_builder__distanceVerifyThreshold = 1.5;
                                            building_builder__minDistanceToMissionRespawns = -1.0;
                                            building_builder__minDistanceToCapturePoints = -1.0;
                                            building_builder__maxUnderwaterDistance = -1.0;
                                            ri_preview__name : das_string const?;
                                            previewCollres : CollisionResource const?;
                                            previewCollobj : CollisionObject;
                                            previewCollobjOffset : float;
                                            buildingCost : float;
                                            destroyInactiveTimeOut : float const?;
                                            var destroyByInactiveShredderAtTime : float?)
    let buildingPos = transform[3]
    if length_sq(buildingPos - operatorPos) > square(human_use_object__useDist + building_builder__distanceVerifyThreshold)
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    if team != previewTeam
      sendEvent(operatorEid, [[CmdHeroLogEvent event="building_cannot_confirm_by_enemy", text="building_cannot_confirm_by_enemy"]])
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    if destroyByInactiveShredderAtTime != null && destroyInactiveTimeOut != null
      *destroyByInactiveShredderAtTime = building_action__lastActionAtTime + *destroyInactiveTimeOut

    let buildingSpeedMul = get_engineer_building_speed_mul(human_weap__gunEids)
    if building_builder__timeToBuild >= building_builder__maxTimeToBuild
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return //we have already completed the construction of this object preview and it will be removed
    let timeToBuild = building_builder__timeToBuild + (info.curTime - building_action__lastActionAtTime) * buildingSpeedMul * entity_mods__timeToBuildMul
    building_action__lastActionAtTime = info.curTime

    if timeToBuild >= building_builder__maxTimeToBuild
      if is_human_respawn_selector_in_radius_for_team(buildingPos, building_builder__minDistanceToMissionRespawns, previewTeam)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_too_close_to_respawns", text="building_blocked_too_close_to_respawns"]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      if !is_distance_to_capture_points_valid(buildingPos, building_builder__minDistanceToCapturePoints)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_too_close_to_capture_points", text="building_blocked_too_close_to_capture_points"]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      let baseCollres = get_building_collres(previewCollres, ri_preview__name)
      if is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj, previewCollobjOffset, eid, baseCollres)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_cannot_confirm_when_objects_in", text="building_cannot_confirm_when_objects_in"]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      if is_conflict_with_water(buildingPos, building_builder__maxUnderwaterDistance)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_underwater", text="building_blocked_underwater"]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      if is_not_attachable_gun(eid)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_gun_not_attachable", text="building_gun_not_attachable"]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      let restrictedZoneEid = find_building_restricted_zone(buildingPos, builder_info__team)
      if !!restrictedZoneEid
        let locId = get_string(restrictedZoneEid, "building_restricted_zone__messageLocId", "building_blocked_restricted_zone")
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_restricted_zone", text=locId]])
        send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      createEntity("{additionalBuildingTemplate}+{instantiateTemplate}") <| $(var init : ComponentsInitializer)
        set(init, "transform", transform)
        set(init, "buildTypeId", buildTypeId)
        set(init, "buildByPlayer", buildByPlayer)
        set(init, "buildByEngineerEid", buildByEngineerEid)
        set(init, "builder_info__squadEid", builder_info__squadEid)
        set(init, "builder_info__guid", builder_info__guid)
        set(init, "builder_info__team", builder_info__team)
        set(init, "buildingRadius", buildingRadius)
        set(init, "buildingSoundTag", buildingSoundTag)
        set(init, "buildingCost", buildingCost)
        set(init, "build_attach__riexHandle", build_attach__riexHandle)
        if savePreviewTeam
          set(init, "team", previewTeam)
      send_net_event(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      building_builder__timeToBuild = timeToBuild
      destroyEntity(eid)
    else
      building_builder__timeToBuild = timeToBuild

[es(on_appear, tag=gameClient, REQUIRE=buildByPlayer)]
def builded_turret_visual_shoot_tm_es(evt : Event; transform : float3x4; var turret_current_visual_shoot_tm : float3x4)
  turret_current_visual_shoot_tm = transform
