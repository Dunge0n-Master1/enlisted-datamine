require enlisted.game.es.fortifications_build_common
require enlisted.events_enlisted
require game.es.battle_area_common
require game.utils.hero
require game.utils.team
require DagorMathUtils
require game.es.events
require danetlibs.native_dasevents.main.native_events
require EnlistedHuman
require DagorSystem
require ecs.common
require math.base
require HumanPhys
require DagorMath
require PhysVars
require RendInst
require ecs.safe
require CollRes
require PhysMat
require Dacoll
require zones
require math
require ecs
require app
require EnlistedNet
require common_shooter.events_common_shooter

[es(on_appear)]
def building_preview_collobj_init_es(evt : Event;
                                     ri_preview__name : das_string const?;
                                     previewCollres : CollisionResource const?;
                                     preview_phys__blk : string;
                                     var previewCollobj : CollisionObject)
  let baseCollres = get_building_collres(previewCollres, ri_preview__name)
  if baseCollres != null
    add_dynamic_collision_from_coll_resource(previewCollobj, *baseCollres, preview_phys__blk)

[es(on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def building_preview_collobj_cleanup_es(evt : Event; var previewCollobj : CollisionObject)
  destroy_dynamic_collision(previewCollobj)

def is_pitch_in_range(vec, limits)
  let angle = 90.0 - rad_to_deg(dir_to_angles(vec).y)
  return angle > limits.x && angle < limits.y

[es(tag=server, on_appear, before=building_preview_inactive_destroyes_es)]
def building_preview_destroy_timer_create_es(evt : Event;
                                             destroyInactiveTimeOut : float;
                                             var destroyByInactiveShredderAtTime : float&)
  destroyByInactiveShredderAtTime = get_sync_time() + destroyInactiveTimeOut

def set_ri_preview_box_size(ri_preview_name : string;
                            var box_min : float3&;
                            var box_max : float3&)
  let resIndex = get_rigen_extra_res_idx(ri_preview_name)
  let resBox = riex_get_lbb(resIndex)
  box_min = resBox.bmin.xyz
  box_max = resBox.bmax.xyz

[es(tag=gameClient, before=build_ability_update_transform_es, REQUIRE=builder_preview, REQUIRE_NOT=builder_server_preview)]
def building_preview_rendinst_update_es(info : UpdateStageInfoAct;
                                        ri_preview__name : string;
                                        var buildingBoxMin : float3&;
                                        var buildingBoxMax : float3&)
  if length_sq(buildingBoxMax - buildingBoxMin) == 0.f
    set_ri_preview_box_size(ri_preview__name, buildingBoxMin, buildingBoxMax)

[es(on_appear, before=(build_ability_update_transform_es, building_fortification_building_object))]
def building_preview_rendinst_init_es(info : UpdateStageInfoAct;
                                      ri_preview__name : string;
                                      var buildingBoxMin : float3&;
                                      var buildingBoxMax : float3&)
  set_ri_preview_box_size(ri_preview__name, buildingBoxMin, buildingBoxMax)

def set_animchar_preview_box_size(transform : float3x4;
                                  animchar_bbox : bbox3f;
                                  var box_min : float3&;
                                  var box_max : float3&)
  box_min = animchar_bbox.bmin.xyz - transform[3]
  box_max = animchar_bbox.bmax.xyz - transform[3]

[es(tag=gameClient, before=build_ability_update_transform_es, REQUIRE=builder_preview, REQUIRE_NOT=builder_server_preview)]
def building_preview_animchar_update_es(info : UpdateStageInfoAct;
                                        animchar_bbox : bbox3f;
                                        nextCheckGridObjectsTime : float;
                                        var buildingBoxMin : float3&;
                                        transform : float3x4;
                                        var buildingBoxMax : float3&)
  if get_sync_time() >= nextCheckGridObjectsTime
    set_animchar_preview_box_size(transform, animchar_bbox, buildingBoxMin, buildingBoxMax)

[es(on_appear, before=(build_ability_update_transform_es, building_fortification_building_object))]
def building_preview_animchar_init_es(evt : Event;
                                      animchar_bbox : bbox3f;
                                      transform : float3x4;
                                      var buildingBoxMin : float3&;
                                      var buildingBoxMax : float3&)
  set_animchar_preview_box_size(transform, animchar_bbox, buildingBoxMin, buildingBoxMax)

def is_required_unlocks_available(unlock, squad_eid)
  var unlockFound = false
  ecs::query(squad_eid) <| $ [es] (buildings__unlockIds : IntList)
    unlockFound = find_index(buildings__unlockIds, unlock) >= 0
  return unlockFound

[es(tag=gameClient, no_order, REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))]
def build_ability_update_transform_es(info : UpdateStageInfoAct;
                                      eid : EntityId;
                                      avaliableAngles : float2;
                                      avaliableColor : float3;
                                      blockedColor : float3;
                                      warningColor : float3;
                                      buildingDistance : float;
                                      additionalHeight : float;
                                      additionalYawRotation : float;
                                      buildingBoxMin : float3;
                                      buildingBoxMax : float3;
                                      checkGridObjectsTimeInterval : float;
                                      building_builder__minDistanceToMissionRespawns = -1.0;
                                      building_builder__minDistanceToCapturePoints = -1.0;
                                      building_builder__maxUnderwaterDistance = -1.0;
                                      shredInDeactivatingBattleArea : Tag const?;
                                      requiredSpaceAboveObject = 0.0;
                                      ri_preview__name : das_string const?;
                                      previewCollres : CollisionResource const?;
                                      previewCollobj : CollisionObject;
                                      previewCollobjOffset : float;
                                      buildingCost : float;
                                      preview_render__enabled : bool = true;
                                      var buildingNorm : float3&;
                                      var nextCheckGridObjectsTime : float&;
                                      var transform : float3x4;
                                      var semi_transparent__placingColor : float3&;
                                      var semi_transparent__visible : bool&;
                                      var animchar_render__enabled : bool?)
  if animchar_render__enabled != null
    *animchar_render__enabled = preview_render__enabled

  if !preview_render__enabled
    semi_transparent__visible = false
    return

  var norm : float3
  var build_position : float3
  var isAngleValid = true
  var aimTm : float3x4;
  var heroStock = 0.f
  var availableByCountLimit = true
  var heroTeam = TEAM_UNASSIGNED
  var squadEid = INVALID_ENTITY_ID
  var previewId = -1
  ecs::find_query() <| $ [es(REQUIRE=hero)] (human__aimTm : float3x4;
                                             human_use_object__selectedBuilding : EntityId;
                                             human_weap__currentGunEid : EntityId;
                                             possessedByPlr : EntityId;
                                             squad_member__squad : EntityId;
                                             stockOfBuilderCapabilities : float;
                                             team : int = TEAM_UNASSIGNED;
                                             bindedCamera : EntityId)
    heroTeam = team
    squadEid = squad_member__squad
    if has(human_use_object__selectedBuilding, "builder_server_preview")
      semi_transparent__visible = false
      return true
    heroStock = stockOfBuilderCapabilities
    previewId = get_int(human_weap__currentGunEid, "currentPreviewId") ?? -1
    let rayMatId = get_int(human_weap__currentGunEid, "fortification__rayMatId") ?? PHYSMAT_INVALID;;
    availableByCountLimit = count_available_buildings_by_type(possessedByPlr, previewId) != 0
    semi_transparent__visible = true
    aimTm = human__aimTm
    let tracePos = aimTm[3]
    //We save hands position and try to use camera tm if it available (swap XZ in camera TM)
    ecs::query(bindedCamera) <| $ [es] (transform : float3x4; isTpsView : bool = false)
      if isTpsView
        return
      aimTm[0] = transform[2]
      aimTm[2] = -transform[0]
      aimTm[1] = transform[1]

    let traceDir = aimTm[0]
    var len = buildingDistance
    var height = 100.0
    let traceAdditionEps = float3(0.0, 0.05, 0.0)
    var riMatId = PHYSMAT_INVALID
    var riDesc = RendInstDesc()
    traceray_normalized(tracePos, traceDir, len, riMatId, norm, ETF_ALL | ETF_RI_PHYS, riDesc, rayMatId)
    build_position = tracePos + traceDir * len
    if length(norm) == 0.f
      if !tracedown_normalized_with_mat_id(build_position + traceAdditionEps, height, norm, ETF_DEFAULT | ETF_RI_PHYS, rayMatId)
        return true
      build_position.y -= height - traceAdditionEps.y

    if dot(norm, traceDir) >= 0.f //In case if normal is inverted
      norm = -norm
    build_position.y += additionalHeight
    buildingNorm = norm
    isAngleValid = is_pitch_in_range(norm, avaliableAngles)
    return true

  if !semi_transparent__visible || length_sq(aimTm[0]) == 0.f
    return
  if length_sq(norm) == 0.f
    norm = float3(0.f, 1.f, 0.f)
  if isAngleValid
    transform[1] = norm
  transform[0] = normalize(cross(transform[1], aimTm[2]))
  transform[0] = quat(norm, deg_to_rad(additionalYawRotation)) * transform[0]
  transform[2] = normalize(cross(transform[0], transform[1]))
  transform[3] = build_position
  let syncTime = get_sync_time()
  if syncTime > nextCheckGridObjectsTime
    let baseCollres = get_building_collres(previewCollres, ri_preview__name)
    let buildPos = build_position
    let bboxDiagonal = buildingBoxMax - buildingBoxMin
    let bboxDiagonalXZLength =  length(bboxDiagonal.xz)
    let minDistanceToCapturePoints = building_builder__minDistanceToCapturePoints
    let minDistanceToMissionRespawns = building_builder__minDistanceToMissionRespawns
    let maxUnderwaterDistance = building_builder__maxUnderwaterDistance
    let priceLimitReached = heroStock < buildingCost
    let allowRecreate = has(eid, "destroySimilarBuilding")
    let isValid = (isAngleValid &&
                   !priceLimitReached &&
                   (availableByCountLimit || allowRecreate) &&
                   is_required_unlocks_available(previewId, squadEid) &&
                   is_required_space_above_object_free(buildPos, bboxDiagonalXZLength, requiredSpaceAboveObject) &&
                   is_distance_to_capture_points_valid(buildPos, minDistanceToCapturePoints) &&
                   !is_conflict_with_water(buildPos, maxUnderwaterDistance) &&
                   !is_human_respawn_selector_in_radius_for_team(buildPos, minDistanceToMissionRespawns, heroTeam) &&
                   !is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj,
                     previewCollobjOffset, eid, baseCollres) &&
                   has_active_human_battle_area_at(buildPos, heroTeam) &&
                   (shredInDeactivatingBattleArea == null || has_active_non_deactivating_human_battle_area_at(buildPos, heroTeam)) &&
                   !is_not_attachable_gun(eid) &&
                   !is_in_building_restricted_zone(buildPos, heroTeam))
    if isValid
      semi_transparent__placingColor = !availableByCountLimit && allowRecreate ? warningColor : avaliableColor
    else
      semi_transparent__placingColor = blockedColor
    nextCheckGridObjectsTime = syncTime + checkGridObjectsTimeInterval

def get_verified_fortification_template_name(templateName, fortificationTm, builderPos, notificationEid, buildingTeam, builder_resources, squad_eid, preview_id)
  let tpl = getTemplateByName(templateName)
  if tpl == null
    logerr("template {templateName} doesn't exist")
    return ""
  if !is_required_unlocks_available(preview_id, squad_eid)
    sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_by_unlock",
                                                 text="building_blocked_by_unlock"]])
    return ""

  if templateHasComponent(*tpl, "shredInDeactivatingBattleArea")
    if !has_active_non_deactivating_human_battle_area_at(fortificationTm[3], buildingTeam)
      sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_in_deactivating_battle_area", text="building_blocked_in_deactivating_battle_area"]])
      return ""

  let avaliableAngles = getTemplateComponent(*tpl, "avaliableAngles") ?as float2
  if avaliableAngles == null
    logerr("Angle limits aren't specified in template {templateName}")
    return ""
  let norm = fortificationTm[1]
  if !is_pitch_in_range(norm, *avaliableAngles)
    return ""
  let buildingCost = getTemplateComponent(*tpl, "buildingCost") ?? 0.0
  if buildingCost > builder_resources
    return ""
  let buildingDistance = getTemplateComponent(*tpl, "buildingDistance") ?? 0.0
  var buildingPosForVerification = fortificationTm[3]
  buildingPosForVerification.y = builderPos.y
  let distance = length(builderPos - buildingPosForVerification)
  let eps = 1.0
  if distance > buildingDistance + eps // When moving, positions on client and on server are different
    sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_by_distance", text="building_blocked_by_distance"]])
    return ""

  let maxUnderwaterDistance = getTemplateComponent(*tpl, "building_builder__maxUnderwaterDistance") ?? -1.0
  if is_conflict_with_water(fortificationTm[3], maxUnderwaterDistance)
    sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_underwater", text="building_blocked_underwater"]])
    return ""

  let minDistanceToCapturePoints = getTemplateComponent(*tpl, "building_builder__minDistanceToCapturePoints") ?? -1.0
  if !is_distance_to_capture_points_valid(buildingPosForVerification, minDistanceToCapturePoints)
    sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_too_close_to_capture_points", text="building_blocked_too_close_to_capture_points"]])
    return ""

  let instantiateComp = getTemplateComponent(*tpl, "instantiateTemplate") ?? ""
  if empty(instantiateComp)
    logerr("instantiateTemplate isn't specified in template {templateName}")
    return ""
  return instantiateComp


def find_same_building(player_eid; build_type_id)
  var buildingEid = INVALID_ENTITY_ID
  var minTime = get_sync_time()
  query() <| $ [es] (eid : EntityId; buildByPlayer : EntityId; buildTypeId : int; buildingCostructedAtTime : float)
    if player_eid == buildByPlayer && buildTypeId == build_type_id && buildingCostructedAtTime < minTime
      buildingEid = eid
      minTime = buildingCostructedAtTime
  return buildingEid


def is_preview_allow_recreate(template_name)
  let templatePtr = template_name |> getTemplateByName
  return templatePtr != null && *templatePtr |> templateHasComponent("destroySimilarBuilding")

[es(tag=server, track=gun__owner, on_appear)]
def init_available_buildings_es(evt : Event;
                                gun__owner : EntityId;
                                buildingLimits : IntList)
  query(gun__owner) <| $ [es] (possessedByPlr : EntityId;
                               squad_member__squad : EntityId = INVALID_ENTITY_ID)
    let player = (!!possessedByPlr ? possessedByPlr : get_Eid(squad_member__squad, "squad__ownerPlayer") ?? INVALID_ENTITY_ID)
    query(player) <| $ [es] (var availableBuildings : IntList)
      if length(availableBuildings) != 0
        return
      resize(availableBuildings, length(buildingLimits))
      for i in iter_range(buildingLimits)
        availableBuildings[i] = buildingLimits[i]

def trace_ri_under_building(building_pos : float3; building_radius : float; rayMatId : int = PHYSMAT_INVALID)
  var norm : float3
  var len = building_radius
  var riMatId = PHYSMAT_INVALID
  var riDesc = RendInstDesc()
  let traceDownDir = float3(0., -1., 0.)
  let tracePos = building_pos - traceDownDir * (building_radius / 2.)
  traceray_normalized(tracePos, traceDownDir, len, riMatId, norm, ETF_ALL, riDesc, rayMatId)
  return riDesc.riExtraHandle

[es(tag=server)]
def build_fortification_es(evt : CmdBuildFortification;
                           eid : ecs::EntityId;
                           human__aimTm : float3x4;
                           human_weap__currentGunEid : ecs::EntityId;
                           team : int;
                           stockOfBuilderCapabilities : float;
                           squad_member__playerEid : EntityId;
                           squad_member__squad : EntityId;
                           guid : string)
  if human_weap__currentGunEid != evt.builderGunEid
    return
  let previewTm = evt.tm
  let curTime = get_sync_time()
  ecs::query(human_weap__currentGunEid) <| $ [es] (previewTemplate : StringList;
                                                   additionalBuildingTemplate : string;
                                                   currentPreviewId : int;
                                                   buildingInterval : float;
                                                   minBuildingRadius : float;
                                                   var nextBuildingAtTime : float&;
                                                   fortification__rayMatId : int = PHYSMAT_INVALID)
    if !has_active_human_battle_area_at(previewTm[3], team)
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_outside_battle_area", text="building_blocked_outside_battle_area"]])
      return
    if nextBuildingAtTime > curTime
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_by_time", text="building_blocked_by_time"]])
      return
    let fortificationTemplate = get_verified_fortification_template_name(string(previewTemplate[currentPreviewId]),
                                                                         previewTm,
                                                                         human__aimTm[3],
                                                                         eid,
                                                                         team,
                                                                         stockOfBuilderCapabilities,
                                                                         squad_member__squad,
                                                                         currentPreviewId)
    if fortificationTemplate == ""
      return
    let existBuildingEid = (is_preview_allow_recreate(string(previewTemplate[currentPreviewId])) ?
      find_same_building(squad_member__playerEid, currentPreviewId) : INVALID_ENTITY_ID)

    let count = count_available_buildings_by_type(squad_member__playerEid, currentPreviewId)
    if count == 0 && !existBuildingEid
      return
    nextBuildingAtTime = curTime + buildingInterval
    let buildingRadius = max(length(evt.boxMax - evt.boxMin) * 0.5, minBuildingRadius)
    let attachToRi = trace_ri_under_building(previewTm[3], buildingRadius, fortification__rayMatId)
    createEntity("{additionalBuildingTemplate}+{previewTemplate[currentPreviewId]}") <| $(var init : ComponentsInitializer)
      set(init, "transform", previewTm)
      set(init, "buildingRadius", buildingRadius)
      set(init, "buildTypeId", currentPreviewId)
      set(init, "previewTeam", team)
      set(init, "buildByPlayer", squad_member__playerEid)
      set(init, "buildByEngineerEid", eid)
      set(init, "builder_info__squadEid", squad_member__squad)
      set(init, "builder_info__guid", guid)
      set(init, "builder_info__team", team)
      set(init, "build_attach__riexHandle", attachToRi)

def is_valid_preview_template_for_soldier(owner, build_id)
  var squadEid = INVALID_ENTITY_ID
  query(owner) <| $ [es] (squad_member__squad : EntityId)
    squadEid = squad_member__squad
  return is_required_unlocks_available(build_id, squadEid)

[es(tag=server)]
def next_building_type_es(evt : CmdNextBuildingType;
                          previewTemplate : StringList;
                          gun__owner : EntityId;
                          var currentPreviewId : int&)
  let templatesCount = length(previewTemplate)
  for i in range(1, templatesCount)
    let verificateId = (currentPreviewId + i) % templatesCount
    if is_valid_preview_template_for_soldier(gun__owner, verificateId)
      currentPreviewId = verificateId
      return

[es(tag=server, on_appear)]
def verificate_build_id_on_create_es(evt : Event;
                                     eid : EntityId;
                                     currentPreviewId : int;
                                     gun__owner : ecs::EntityId)
  if !is_valid_preview_template_for_soldier(gun__owner, currentPreviewId)
    send_net_event(eid, [[CmdNextBuildingType]])

[es(tag=gameClient, on_appear)]
def fortification_mat_init_create_es(evt : Event;
                                     fortification__rayMatName : string;
                                     var fortification__rayMatId : int&)
  fortification__rayMatId = get_material_id(fortification__rayMatName)

[es(tag=server)]
def select_building_type_es(evt : CmdSelectBuildingType; previewTemplate : StringList; var currentPreviewId : int&)
  let index = get_int(evt.data, "index")
  if index == null
    logerr("Received CmdSelectBuildingType event missing payload 'index'")
  elif * index < length(previewTemplate)
    currentPreviewId = *index
  else
    logerr("Trying to select building type out of previewTemplate's range ({*index} [0..{length(previewTemplate)}])")

[es(on_appear, tag=gameClient, before=anim_phys_init_es)]
def animvars_for_building_preview_es(evt : Event; var phys_vars : PhysVars; previewAnimVarParams : StringList; previewAnimVarParamsValue : FloatList)
  for paramNo in iter_range(previewAnimVarParams)
    let paramId = registerVar(phys_vars, string(previewAnimVarParams[paramNo]), 0.0)
    setVar(phys_vars, paramId, previewAnimVarParamsValue[paramNo])

[es(on_appear, tag=server)]
def building_create_es(evt : Event; eid : EntityId; buildTypeId : int; buildByPlayer : ecs::EntityId; var buildingCostructedAtTime : float&)
  buildingCostructedAtTime = get_sync_time()
  change_building_limits(buildByPlayer, buildTypeId, -1)

  let count = count_available_buildings_by_type(buildByPlayer, buildTypeId)
  if count < 0 && has(eid, "destroySimilarBuilding")
    destroyEntity(find_same_building(buildByPlayer, buildTypeId))

[es(on_event=EventEntityDestroyed, tag=server)]
def building_destroyed_es(evt : Event; buildTypeId : int; buildByPlayer : ecs::EntityId; additiveBuildNeedRepair : bool = false)
  if !additiveBuildNeedRepair
    change_building_limits(buildByPlayer, buildTypeId, 1)

[es(on_event=EventEntityDied, tag=server)]
def building_died_es(evt : Event; buildTypeId : int; var buildByPlayer : ecs::EntityId&)
  change_building_limits(buildByPlayer, buildTypeId, 1)
  buildByPlayer = INVALID_ENTITY_ID

[es(tag=gameClient, track=currentPreviewId, REQUIRE=currentPreviewId)]
def hero_change_build_id_es(evt : Event;
                            gun__owner : ecs::EntityId)
  if !has(gun__owner, "hero")
    return
  sendEvent(gun__owner, [[EventRecreateBuildPreview]])

[es(tag=gameClient, on_event=EventTryBuildFortification, after=build_ability_update_transform_es, REQUIRE=builder_preview)]
def try_build_fortification_es(evt : Event;
                               eid : EntityId;
                               transform : float3x4;
                               avaliableAngles : float2;
                               buildingNorm : float3;
                               builderGunEid : ecs::EntityId;
                               buildingBoxMin : float3;
                               buildingBoxMax : float3;
                               buildingCost : float;
                               building_builder__minDistanceToMissionRespawns = -1.0;
                               building_builder__minDistanceToCapturePoints = -1.0;
                               building_builder__maxUnderwaterDistance = -1.0;
                               requiredSpaceAboveObject = 0.0;
                               previewCollres : CollisionResource const?;
                               ri_preview__name : das_string const?;
                               previewCollobj : CollisionObject;
                               previewCollobjOffset : float)
  let hero = get_controlled_hero()
  var actionWithObj = INVALID_ENTITY_ID
  var equipped = false
  var heroTeam = TEAM_UNASSIGNED
  var builderStock = 0.0
  ecs::query(hero) <| $ [es] (human_net_phys : HumanActor; building_action__target : EntityId; stockOfBuilderCapabilities : float; team = TEAM_UNASSIGNED)
    equipped = human_net_phys.phys.currentState.weapEquipState.curState ==  HUWeaponEquipState EES_EQUIPED
    actionWithObj = building_action__target
    heroTeam = team
    builderStock = stockOfBuilderCapabilities
  if builderStock < buildingCost
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_no_require_resources", text="building_blocked_no_require_resources"]])
    return
  if !equipped || actionWithObj != INVALID_ENTITY_ID
    return
  if !is_pitch_in_range(buildingNorm, avaliableAngles)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_by_angle", text="building_blocked_by_angle"]])
    return
  let baseCollres = get_building_collres(previewCollres, ri_preview__name)
  if is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj, previewCollobjOffset, eid, baseCollres)
    sendEvent(hero, [[CmdHeroLogEvent event="building_cannot_confirm_when_objects_in", text="building_cannot_confirm_when_objects_in"]])
    return
  if is_not_attachable_gun(eid)
    sendEvent(hero, [[CmdHeroLogEvent event="building_gun_not_attachable", text="building_gun_not_attachable"]])
    return
  let buildingPos = transform[3]
  if !!is_human_respawn_selector_in_radius_for_team(buildingPos, building_builder__minDistanceToMissionRespawns, heroTeam)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_too_close_to_respawns", text="building_blocked_too_close_to_respawns"]])
    return
  if !is_distance_to_capture_points_valid(buildingPos, building_builder__minDistanceToCapturePoints)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_too_close_to_capture_points", text="building_blocked_too_close_to_capture_points"]])
    return
  if is_conflict_with_water(buildingPos, building_builder__maxUnderwaterDistance)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_underwater", text="building_blocked_underwater"]])
    return
  let bboxDiagonal = buildingBoxMax - buildingBoxMin
  let bboxDiagonalXZLength = length(bboxDiagonal.xz)
  if !is_required_space_above_object_free(buildingPos, bboxDiagonalXZLength, requiredSpaceAboveObject)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_not_enough_free_space_to_spawn", text="building_blocked_not_enough_free_space_to_spawn"]])
    return
  let restrictedZoneEid = find_building_restricted_zone(buildingPos, heroTeam)
  if !!restrictedZoneEid
    let locId = get_string(restrictedZoneEid, "building_restricted_zone__messageLocId", "building_blocked_restricted_zone")
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_restricted_zone", text=locId]])
    return
  send_net_event(hero, [[CmdBuildFortification builderGunEid = builderGunEid,
                                          tm = transform,
                                          boxMin = buildingBoxMin,
                                          boxMax = buildingBoxMax]])

[es(tag=gameClient)]
def hero_change_build_es(evt : EventHeroChanged)
  sendEvent(evt.eid, [[EventRecreateBuildPreview]])

[es(tag=gameClient, track=(human_weap__currentGunEid, isInVehicle, isAlive), REQUIRE=(hero, isAlive, human_weap__currentGunEid, isInVehicle))]
def hero_weapon_changed_build_es(evt : Event; eid : ecs::EntityId)
  sendEvent(eid, [[EventRecreateBuildPreview]])

[es(tag=gameClient)]
def select_build_tool_on_client(evt : EventRecreateBuildPreview;
                                human_weap__currentGunEid : ecs::EntityId;
                                isAlive = true;
                                isInVehicle = false)
  query() <| $ [es(REQUIRE=builder_preview, REQUIRE_NOT=(builder_additive_preview, builder_server_preview))] (eid : ecs::EntityId)
    destroyEntity(eid)
  if isInVehicle || !isAlive
    return
  ecs::query(human_weap__currentGunEid) <| $ [es] (var previewEid : ecs::EntityId&; previewTemplate : StringList; currentPreviewId : int)
    previewEid = createEntity(string(previewTemplate[currentPreviewId])) <| $(var init : ComponentsInitializer)
      set(init, "builderGunEid", human_weap__currentGunEid)

def build_fortification_immediately(owner : EntityId; isShootPressed : bool)
  var buildingNow = false;
  ecs::query(owner) <| $ [es] (human_use_object__selectedBuilding : EntityId;
                               building_action__target : EntityId)
    let selectBuilding = has(human_use_object__selectedBuilding, "builder_server_preview")
    if selectBuilding
      buildingNow = true
      if isShootPressed
        if building_action__target != INVALID_ENTITY_ID
          return
        send_net_event(owner, [[EventSetBuildingTarget target = human_use_object__selectedBuilding]])
        return
  return buildingNow

[es(tag=gameClient)]
def start_build_fortification_es(evt : CmdWeapPhysUpdate;
                                 previewEid : ecs::EntityId;
                                 autoTryBuildingObjectInterval : float;
                                 var nextTryToSetObjectInTime : float&;
                                 var builder__shootPressed : bool&)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  if !previewEid
    return
  let curTime = get_sync_time()
  if isShootPressed && !builder__shootPressed && nextTryToSetObjectInTime < curTime
    nextTryToSetObjectInTime = curTime + autoTryBuildingObjectInterval
    sendEvent(previewEid, [[EventTryBuildFortification]])
  elif !isShootPressed
    builder__shootPressed = false
    nextTryToSetObjectInTime = -1.0


[es(tag=gameClient, before=start_build_fortification_es)]
def start_building_action_fortification_es(evt : CmdWeapPhysUpdate;
                                           var builder__shootPressed : bool&)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  var buildPreviewWasStarted = false
  let canTryStartBuilding = isShootPressed != builder__shootPressed
  if canTryStartBuilding
    if !isShootPressed
      send_net_event(evt.owner, [[EventSetBuildingTarget target = INVALID_ENTITY_ID]])
    buildPreviewWasStarted = build_fortification_immediately(evt.owner, isShootPressed)
    builder__shootPressed = buildPreviewWasStarted && isShootPressed


def is_building_action_blocked(building_action__target : EntityId;
                               blockedColor : float3;
                               placingColor : float3)
  return !building_action__target && is_equal_float(placingColor, blockedColor, 0.01)


[es(tag=gameClient, on_appear, track=semi_transparent__placingColor)]
def fortification_preview_update_melee_ability_preview(evt : Event;
                                                       blockedColor : float3;
                                                       builderGunEid : EntityId;
                                                       semi_transparent__placingColor : float3)
  query(builderGunEid) <| $ [es] (gun__owner : EntityId; var melee_weapon__isActionBlocked : bool&)
    let buildingTargetEid = get_Eid(gun__owner, "building_action__target") ?? INVALID_ENTITY_ID
    melee_weapon__isActionBlocked = is_building_action_blocked(buildingTargetEid, blockedColor, semi_transparent__placingColor)


[es(tag=gameClient, on_appear, track=building_action__target)]
def fortification_preview_update_melee_ability_human(evt : Event;
                                                     building_action__target : EntityId;
                                                     human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=buildingTool)] (previewEid : EntityId;
                                                                    var melee_weapon__isActionBlocked : bool&)
    query(previewEid) <| $ [es] (blockedColor : float3;
                                 semi_transparent__placingColor : float3)
      melee_weapon__isActionBlocked = is_building_action_blocked(building_action__target, blockedColor, semi_transparent__placingColor)
