require ecs
require ecs.common
require enlisted.tutorial.tutorial_common
require DagorMath
require strings

[es(on_event=EventEntityCreated)]
def engineer_tutorial_build_fortication_init_es(evt : Event; tutor_stage__buildForticationAtZone : string)
  set_tutorial_zone_active(tutor_stage__buildForticationAtZone, true)

[es(on_event=EventEntityDestroyed)]
def engineer_tutorial_build_fortication_destroy_es(evt : Event; tutor_stage__buildForticationAtZone : string)
  set_tutorial_zone_active(tutor_stage__buildForticationAtZone, false)

[es(on_event=EventEntityCreated, REQUIRE=instantiateTemplate)]
def engineer_tutorial_start_build_fortication_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_stage__forticationStartBuild)] (eid : EntityId)
    destroyEntity(eid)

[es(on_appear, REQUIRE=ammo_holder__ammoCount)]
def remove_player_ammo_es(evt : Event; eid : EntityId)
  find_query() <| $ [es(REQUIRE=tutor_action__destroyPlayerAmmo)] ()
    destroyEntity(eid)
    return true

[es(on_appear, track=gun__ammo)]
def remove_human_ammo_from_gun_es(evt : Event; var gun__ammo : int&)
  if gun__ammo == 0
    return

  find_query() <| $ [es(REQUIRE=tutor_action__destroyPlayerAmmo)] ()
    gun__ammo = 0
    return true

[es(on_appear)]
def engineer_tutorial_build_fortication_stage_active_es(evt : Event;
                                                        eid : EntityId;
                                                        tutor_stage__buildFortication : string;
                                                        tutor_stage__buildForticationAtZone : string)
  find_query() <| $ [es] (tutorial_zone__active : bool;
                          tutorial_zone__zoneId : string;
                          transform aka zone_transform : float3x4)
    if !tutorial_zone__active || tutor_stage__buildForticationAtZone != tutorial_zone__zoneId
      return false

    find_query() <| $ [es] (building_menu__text : string; transform : float3x4; ri_extra__bboxMin : float3; ri_extra__bboxMax : float3)
      if tutor_stage__buildFortication != building_menu__text
        return false

      let buildingBox = BBox3(ri_extra__bboxMin, ri_extra__bboxMax)
      if check_tutorial_zone(transform, buildingBox, zone_transform, int(ZoneCheck IN_ZONE))
        destroyEntity(eid)
        return true
      return false

    return true

[es(track=tutorial_zone__active, on_appear)]
def engineer_tutorial_build_fortication_zone_active_es(evt : Event;
                                                       tutorial_zone__active : bool;
                                                       tutorial_zone__zoneId : string;
                                                       transform aka zone_transform : float3x4)
  if !tutorial_zone__active
    return

  query() <| $ [es] (eid : EntityId;
                     tutor_stage__buildFortication : string;
                     tutor_stage__buildForticationAtZone : string)
    if tutorial_zone__zoneId != tutor_stage__buildForticationAtZone
      return

    find_query() <| $ [es] (building_menu__text : string; transform : float3x4; ri_extra__bboxMin : float3; ri_extra__bboxMax : float3)
      if tutor_stage__buildFortication != building_menu__text
        return false

      let buildingBox = BBox3(ri_extra__bboxMin, ri_extra__bboxMax)
      if check_tutorial_zone(transform, buildingBox, zone_transform, int(ZoneCheck IN_ZONE))
        destroyEntity(eid)
        return true
      return false

[es(on_event=EventEntityCreated, REQUIRE_NOT=instantiateTemplate)]
def engineer_tutorial_build_fortication_es(evt : Event;
                                           building_menu__text : string;
                                           transform : float3x4;
                                           ri_extra__bboxMin : float3;
                                           ri_extra__bboxMax : float3)
  let buildingTm = transform
  query() <| $ [es] (eid : EntityId;
                     tutor_stage__buildFortication : string;
                     tutor_stage__buildForticationAtZone : string = "")
    if tutor_stage__buildFortication != building_menu__text
      return

    if tutor_stage__buildForticationAtZone == ""
      destroyEntity(eid)
      return

    query() <| $ [es] (tutorial_zone__active : bool; tutorial_zone__zoneId : string; transform : float3x4)
      if !tutorial_zone__active || tutorial_zone__zoneId != tutor_stage__buildForticationAtZone
        return

      let buildingBox = BBox3(ri_extra__bboxMin, ri_extra__bboxMax)
      if check_tutorial_zone(buildingTm, buildingBox, transform, int(ZoneCheck IN_ZONE))
        destroyEntity(eid)

[es(on_event=EventEntityDestroyed, REQUIRE_NOT=instantiateTemplate)]
def engineer_tutorial_destroy_fortication_es(evt : Event; building_menu__text : string)
  query() <| $ [es] (eid : EntityId; tutor_stage__destroyFortication : string)
    if building_menu__text == tutor_stage__destroyFortication
      destroyEntity(eid)

[es(track=human_weap__currentGunEid, REQUIRE=hero, on_appear)]
def tutorial_condition_weapon_change_es(evt : Event; human_weap__currentGunEid : EntityId)
  query() <| $ [es] (eid : EntityId; tutor_condition__weaponChange : string)
    let gunTemplate = split_template(getEntityTemplateName(human_weap__currentGunEid))[0]
    if gunTemplate |> find(tutor_condition__weaponChange) >= 0
      destroyEntity(eid)

[es(on_appear)]
def tutorial_condition_weapon_change_init_es(evt : Event; eid : EntityId; tutor_condition__weaponChange : string)
  query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId)
    let gunTemplate = split_template(getEntityTemplateName(human_weap__currentGunEid))[0]
    if gunTemplate |> find(tutor_condition__weaponChange) >= 0
      destroyEntity(eid)

[es(on_appear, track=engineer__isMenuOpen, REQUIRE=hero)]
def tutorial_condition_open_engineer_menu_es(evt : Event; engineer__isMenuOpen : bool)
  query() <| $ [es(REQUIRE=tutor_condition__engineerOpenMenu)] (eid : EntityId)
    if engineer__isMenuOpen
      destroyEntity(eid)

[es(on_appear, REQUIRE=tutor_condition__engineerOpenMenu)]
def tutorial_condition_open_engineer_menu_init_es(evt : Event; eid : EntityId)
  query() <| $ [es(REQUIRE=hero)] (engineer__isMenuOpen : bool)
    if engineer__isMenuOpen
      destroyEntity(eid)

[es(track=possessedByPlr, REQUIRE=hero, REQUIRE=possessedByPlr)]
def tutorial_condition_change_soldier_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__changeSoldier)] (eid : EntityId)
    destroyEntity(eid)

[es(track=stockOfBuilderCapabilities, on_appear, REQUIRE=hero)]
def tutorial_engineer_resource_observer_es(evt : Event; stockOfBuilderCapabilities : float)
  query() <| $ [es] (eid : EntityId; tutor_condition__lteEngineerResource : float)
    if stockOfBuilderCapabilities <= tutor_condition__lteEngineerResource
      destroyEntity(eid)

  query() <| $ [es] (eid : EntityId; tutor_condition__gteEngineerResource : float)
    if stockOfBuilderCapabilities >= tutor_condition__gteEngineerResource
      destroyEntity(eid)

[es(on_appear)]
def tutorial_engineer_set_resources(evt : Event; tutor_action__setEngineerResources : float)
  query() <| $ [es(REQUIRE=hero)] (var stockOfBuilderCapabilities : float&)
    stockOfBuilderCapabilities = tutor_action__setEngineerResources

[es(on_appear, REQUIRE=tutorial__lockSquadMemberChange)]
def tutorial_lock_squad_member_change_es(evt : Event)
  query() <| $ [es] (var squad__canChangeMember : bool&)
    squad__canChangeMember = false

[es(on_event=EventEntityDestroyed, REQUIRE=tutorial__lockSquadMemberChange)]
def tutorial_unlock_squad_member_change_es(evt : Event)
  query() <| $ [es] (var squad__canChangeMember : bool&)
    squad__canChangeMember = true

[es(on_appear)]
def tutorial_unlock_squad_member_change_on_init_es(evt : Event; var squad__canChangeMember : bool&)
  query() <| $ [es(REQUIRE=tutorial__lockSquadMemberChange)]
    squad__canChangeMember = false

[es(on_event=EventEntityDestroyed, REQUIRE=tutorial_engineer__resupplyHintDisable)]
def destroy_resupply_hint_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__lteEngineerResource)] (eid : EntityId; var tutor_stage__next : das_string&)
    tutor_stage__next := ""
    destroyEntity(eid)

  query() <| $ [es(REQUIRE=tutor_condition__gteEngineerResource)] (eid : EntityId; var tutor_stage__next : das_string&)
    tutor_stage__next := ""
    destroyEntity(eid)

[es(on_appear)]
def tutorial_engineer_unlock_building(evt : Event; tutor_action__unlockBuilding : StringList)
  query() <| $ [es(REQUIRE=hero)] (human_weap__gunEids : EidList; squad_member__squad : EntityId)
    for gunEid in human_weap__gunEids
      query(gunEid) <| $ [es] (previewTemplate : StringList)
        query(squad_member__squad) <| $ [es] (var buildings__unlockIds : IntList)
          buildings__unlockIds |> clear()
          for building in tutor_action__unlockBuilding
            let index = find_index_if(each(previewTemplate)) <| $(val)
              return find(string(val), string(building)) >= 0
            if index >= 0
              buildings__unlockIds |> push(index)

[es(on_appear, track=buildings__unlockIds)]
def tutorial_engineer_unlock_building_es(evt : Event; var buildings__unlockIds : IntList)
  query() <| $ [es] (tutor_action__unlockBuilding : StringList)
    buildings__unlockIds |> clear()
    query() <| $ [es(REQUIRE=hero)] (human_weap__gunEids : EidList)
      for gunEid in human_weap__gunEids
        query(gunEid) <| $ [es] (previewTemplate : StringList)
          for building in tutor_action__unlockBuilding
            let index = find_index_if(each(previewTemplate)) <| $(val)
              return find(string(val), string(building)) >= 0
            if index >= 0
              buildings__unlockIds |> push(index)

[es(on_appear, REQUIRE=hero)]
def tutorial_engineer_lock_building_menu_es(evt : Event; possessedByPlr : EntityId)
  query() <| $ [es] (tutor_action__buildingToolAvailable : bool)
    query(possessedByPlr) <| $ [es] (var engieer__buildingToolAvailable : bool&)
      engieer__buildingToolAvailable = tutor_action__buildingToolAvailable

[es(on_appear)]
def tutorial_engineer_building_avalible_es(evt : Event; tutor_action__buildingToolAvailable : bool)
  find_query() <| $ [es(REQUIRE=player)] (var engieer__buildingToolAvailable : bool&; is_local : bool)
    if is_local
      engieer__buildingToolAvailable = tutor_action__buildingToolAvailable
      return true
    return false
