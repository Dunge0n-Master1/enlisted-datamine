require DagorSystem
require enlisted.game.es.fortifications_build_common
require game.utils.team
require ecs.common
require ecs


def align_tm_by_up_vector(var tm; up)
  if up == null
    return tm
  tm[0] =  normalize(cross(*up, tm[2]))
  tm[1] = -normalize(cross(tm[0], tm[2]))
  tm[2] =  normalize(cross(tm[0], tm[1]))
  return tm

[es(tag=server, on_appear)]
def destroy_invalid_additive_buildings_on_appear(evt : Event; eid : EntityId; dependsOnBuildingEid : EntityId)
  if !doesEntityExist(dependsOnBuildingEid)
    destroyEntity(eid)

[es(tag=gameClient, after=build_ability_update_transform_es)]
def building_additive_preview_depends_es(info : UpdateStageInfoAct;
                                         dependsOnBuildingEid : EntityId;
                                         additiveTm : float3x4&;
                                         additiveUp : float3 const?;
                                         var transform aka preview_transform : float3x4&;
                                         var semi_transparent__placingColor aka preview_semi_transparent__placingColor : float3&;
                                         var semi_transparent__visible aka preview_semi_transparent__visible : bool&)
  ecs::query(dependsOnBuildingEid) <| $ [es] (transform : float3x4; semi_transparent__placingColor : float3; semi_transparent__visible : bool)
    preview_transform = align_tm_by_up_vector(transform * additiveTm, additiveUp)
    preview_semi_transparent__placingColor = semi_transparent__placingColor
    preview_semi_transparent__visible = semi_transparent__visible

def create_additive_buildings(eid, transform, additiveBuildings, team, buildByPlayer, buildByEngineerEid, builder_info__guid, builder_info__squadEid, builder_info__team)
  for i in iter_range(additiveBuildings)
    let obj = get_ecs_object(additiveBuildings[i])
    if obj == null
      continue
    let buildingTemplate = get_string(*obj, "template", "")
    let targetTM = get_TMatrix(obj, "tm")
    if buildingTemplate == "" || targetTM == null
      logerr("can't create all additive buildings for {eid} and {getEntityTemplateName(eid)}, some of them hasn't template or tm")
      continue
    let additiveUp = get_Point3(*obj, "additiveUp")
    let additiveBuildingTm = align_tm_by_up_vector(transform * (*targetTM), additiveUp)
    createEntity(buildingTemplate) <| $(var init : ComponentsInitializer)
      set(init, "transform", additiveBuildingTm)
      set(init, "dependsOnBuildingEid", eid)
      set(init, "buildByPlayer", buildByPlayer)
      set(init, "buildByEngineerEid", buildByEngineerEid)
      if builder_info__guid != ""
        set(init, "builder_info__guid", builder_info__guid)
      if !!builder_info__squadEid
        set(init, "builder_info__squadEid", builder_info__squadEid)
      if builder_info__team != TEAM_UNASSIGNED
        set(init, "builder_info__team", builder_info__team)
      set(init, "additiveTm", (*targetTM))
      set(init, "team", team)
      if additiveUp != null
        set(init, "additiveUp", *additiveUp)

[es(tag=server, on_appear, on_event=EventAdditiveBuildingRepaired, REQUIRE_NOT=builder_preview)]
def init_additive_buildings_es(evt : Event;
                               eid : EntityId;
                               transform : float3x4;
                               additiveBuildings : Array;
                               buildByPlayer : EntityId = INVALID_ENTITY_ID;
                               buildByEngineerEid : EntityId = INVALID_ENTITY_ID;
                               builder_info__guid : string = "";
                               builder_info__squadEid : EntityId = INVALID_ENTITY_ID;
                               builder_info__team : int = TEAM_UNASSIGNED;
                               team = TEAM_UNASSIGNED)
  create_additive_buildings(eid, transform, additiveBuildings, team, buildByPlayer, buildByEngineerEid, builder_info__guid, builder_info__squadEid, builder_info__team)

[es(tag=gameClient, on_appear, REQUIRE=builder_preview)]
def init_additive_local_previews_es(evt : Event;
                                    eid : EntityId;
                                    transform : float3x4;
                                    additiveBuildings : Array;
                                    buildByPlayer : EntityId = INVALID_ENTITY_ID;
                                    buildByEngineerEid : EntityId = INVALID_ENTITY_ID;
                                    builder_info__guid : string = "";
                                    builder_info__squadEid : EntityId = INVALID_ENTITY_ID;
                                    builder_info__team : int = TEAM_UNASSIGNED;
                                    team = TEAM_UNASSIGNED)
  create_additive_buildings(eid, transform, additiveBuildings, team, buildByPlayer, buildByEngineerEid, builder_info__guid, builder_info__squadEid, builder_info__team)

def destroy_additive_buildings(base_eid)
  ecs::query() <| $ [es] (eid : EntityId; dependsOnBuildingEid : EntityId)
    if base_eid == dependsOnBuildingEid
      destroyEntity(eid)

[es(tag=server, on_event=(EventEntityDestroyed, EventEntityDied), REQUIRE=additiveBuildings, REQUIRE_NOT=builder_preview)]
def destroy_additive_buildings_es(evt : Event;
                                  eid : EntityId)
  destroy_additive_buildings(eid)

[es(tag=gameClient, on_event=EventEntityDestroyed, REQUIRE=(additiveBuildings, builder_preview))]
def destroy_additive_previews_es(evt : Event;
                                 eid : EntityId)
  destroy_additive_buildings(eid)

[es(on_event=(EventEntityDestroyed, EventEntityDied), tag=server, REQUIRE=refundForDependsBuilding)]
def on_additive_building_destroyed_es(evt : Event;
                                      dependsOnBuildingEid : ecs::EntityId)
  ecs::query(dependsOnBuildingEid) <| $ [es] (buildTypeId : int;
                                              buildingCost : float;
                                              costReturnedOnDestructionMul : float;
                                              var buildByEngineerEid : EntityId&;
                                              var buildByPlayer : ecs::EntityId&)
    change_building_limits(buildByPlayer, buildTypeId, 1)
    query(buildByEngineerEid) <| $ [es] (var stockOfBuilderCapabilities : float&)
      stockOfBuilderCapabilities += buildingCost * costReturnedOnDestructionMul
    buildByPlayer = INVALID_ENTITY_ID
    buildByEngineerEid = INVALID_ENTITY_ID