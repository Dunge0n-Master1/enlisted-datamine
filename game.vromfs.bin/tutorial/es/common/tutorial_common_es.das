require ecs
require ecs.common
require app
require player
require CollRes
require RendInst
require DagorMath
require math.base
require DagorInput
require game.events_game
require game.utils.team
require enlisted.events_enlisted
require game.es.input.input_events
require enlisted.tutorial.tutorial_common
require enlisted.game.es.client.tutorial_bq_common
require game.es.squad_order_common

def private tutorial_hit_target_process(targetEid; hitTargetByWeapon; currentGunEid; vehicleSelected; attachedGunEid)
  if hitTargetByWeapon == ""
    destroyEntity(targetEid)
    return

  var weaponType = ""
  query(vehicleSelected) <| $ [es] (vehicle_seats__enumVarName : string)
    weaponType = vehicle_seats__enumVarName

  query(attachedGunEid) <| $ [es] (item__weapType : string)
    weaponType = item__weapType

  if weaponType == ""
    query(currentGunEid) <| $ [es] (item__weapType : string)
      weaponType = item__weapType

  if weaponType == "" && has(currentGunEid, "grenade_thrower")
    weaponType = "grenade"

  if hitTargetByWeapon == weaponType
    destroyEntity(targetEid)

def private tutorial_hit_target_ri_process(ri_eid : EntityId;
                                           human_weap__currentGunEid : EntityId;
                                           human_anim__vehicleSelected : EntityId;
                                           human_attached_gun__attachedGunEid : EntityId)
  query() <| $ [es] (eid : EntityId; tutor_stage__hitTarget : string; tutor_stage__hitTargetByWeapon : string = "")
    query(ri_eid) <| $ [es] (tutorial_target__targetId : string; tutorial_target__active : bool = true)
      if !tutorial_target__active || tutorial_target__targetId != tutor_stage__hitTarget
        return

      tutorial_hit_target_process(eid, tutor_stage__hitTargetByWeapon, human_weap__currentGunEid,
        human_anim__vehicleSelected, human_attached_gun__attachedGunEid)

[es(REQUIRE=hero, REQUIRE_NOT=tutorialHuman, on_appear)]
def tutorial_human_init_es(evt : Event; eid : EntityId)
  addSubTemplate(eid, "tutorial_human")

[es(REQUIRE=tutor_stage__complete, on_appear)]
def tutorial_complete(evt : Event)
  broadcastEvent([[EventTeamWon team=get_local_player_team()]])

[es(on_event=EventEntityDestroyed)]
def tutorial_next_stage_es(evt : Event; tutor_stage__next : string)
  if tutor_stage__next != ""
    createEntity(tutor_stage__next)

[es(on_appear)]
def tutorial_stage_remove_group_es(evt : Event; tutor_stage__removeStageGroup : StringList)
  query() <| $ [es] (var tutor_stage__next : das_string&; tutor_stage__group : string)
    if has_value(tutor_stage__removeStageGroup, tutor_stage__group)
      tutor_stage__next := ""

[es(on_disappear, REQUIRE=tutor_stage__displayHint)]
def tutorial_remove_hint_es(evt : Event; tutor_stage__hintGroup : string = "tutorial_hint")
  using() <| $(var arr : Array)
    tutorial_hint(tutor_stage__hintGroup, tutor_stage__hintGroup, "", arr)

[es(on_appear)]
def tutorial_display_hint_es(evt : Event;
                             tutor_stage__displayHint : string;
                             tutor_stage__hintGroup : string = "tutorial_hint";
                             tutor_stage__hintKeys : Array const? = null)
  using() <| $(var arr : Array)
    if tutor_stage__hintKeys != null
      arr := *tutor_stage__hintKeys
    tutorial_hint(tutor_stage__hintGroup, tutor_stage__hintGroup, tutor_stage__displayHint, arr)

[es(on_appear)]
def activate_tutorial_zone_on_create_es(evt : Event; tutorial_zone__zoneId : string; var tutorial_zone__active : bool&)
  query() <| $ [es] (tutor_stage__activateZoneId : string)
    if tutorial_zone__zoneId == tutor_stage__activateZoneId
      tutorial_zone__active = true

[es(on_appear)]
def activate_tutorial_target_on_create_es(evt : Event; tutorial_target__targetId : string; var tutorial_target__active : bool&)
  query() <| $ [es] (tutor_stage__activateTarget : string)
    if tutorial_target__targetId == tutor_stage__activateTarget
      tutorial_target__active = true

[es(on_appear, before=tutorial_create_entity_es)]
def tutorial_activate_zone_es(evt : Event; tutor_stage__activateZoneId : string)
  set_tutorial_zone_active(tutor_stage__activateZoneId, true)

[es(on_appear)]
def tutorial_deactivate_zone_es(evt : Event; tutor_stage__deactivateZoneId : string)
  set_tutorial_zone_active(tutor_stage__deactivateZoneId, false)

[es(on_appear)]
def tutorial_activate_target_es(evt : Event; tutor_stage__activateTarget : string)
  set_target_active(tutor_stage__activateTarget, true)

[es(on_appear)]
def tutorial_deactivate_target_es(evt : Event; tutor_stage__deactivateTarget : string)
  set_target_active(tutor_stage__deactivateTarget, false)

[es(on_appear)]
def tutorial_activate_respawn_es(evt : Event; tutor_stage__activateRespawn : string)
  set_respawn_active(tutor_stage__activateRespawn, true)

[es(on_appear)]
def tutorial_deactivate_respawn_es(evt : Event; tutor_stage__deactivateRespawn : string)
  set_respawn_active(tutor_stage__deactivateRespawn, false)

[es(on_appear)]
def tutorial_hit_target_init_es(evt : Event; tutor_stage__hitTarget : string)
  set_target_active(tutor_stage__hitTarget, true)

[es(on_event=EventEntityDestroyed)]
def tutorial_hit_target_destroy_es(evt : Event; tutor_stage__hitTarget : string)
  set_target_active(tutor_stage__hitTarget, false)

[es(on_appear)]
def tutorial_destroy_target_init_es(evt : Event; tutor_stage__destroyTarget : string)
  set_target_active(tutor_stage__destroyTarget, true)

[es(on_event=EventEntityDestroyed)]
def tutorial_destroy_target_destroy_es(evt : Event; tutor_stage__destroyTarget : string)
  set_target_active(tutor_stage__destroyTarget, false)

[es(on_appear)]
def tutorial_zone_enter_init_es(evt : Event; tutor_stage__playerZoneEnter : string)
  set_tutorial_zone_active(tutor_stage__playerZoneEnter, true)

[es(on_event=EventEntityDestroyed)]
def tutorial_zone_enter_destroy_es(evt : Event; tutor_stage__playerZoneEnter : string)
  set_tutorial_zone_active(tutor_stage__playerZoneEnter, false)

[es(on_appear, REQUIRE=tutor_bq__sendOnBegin)]
def tutorial_bq_on_stage_begin_es(evt : Event; eid : EntityId)
  send_tutorial_stage_bq(getEntityTemplateName(eid))

[es(on_appear, REQUIRE=tutor_bq__sendOnEnd)]
def tutorial_bq_on_stage_finish_es(evt : Event; eid : EntityId)
  send_tutorial_stage_bq(getEntityTemplateName(eid))

[es(on_appear)]
def tutorial_set_spawn_point_es(evt : Event; tutor_action__spawnZoneId : string)
  query() <| $ [es] (tutorial_zone__zoneId : string; transform : float3x4)
    if tutor_action__spawnZoneId != tutorial_zone__zoneId
      return
    let zonePos = transform[3]
    query() <| $ [es(REQUIRE=respbase)] (var transform : float3x4&)
      transform[3] = zonePos

[es(on_appear)]
def tutorial_target_remove_template(evt : Event; tutor_stage__removeTemplateTarget : string; tutor_stage__removeTemplate : string)
  query() <| $ [es] (eid : EntityId; tutorial_target__targetId : string)
    if tutorial_target__targetId == tutor_stage__removeTemplateTarget
      removeSubTemplate(eid, tutor_stage__removeTemplate)

[es(on_appear)]
def tutorial_stage_timer_init_es(evt : Event; tutor_stage__time : float; var tutor_stage__timer : float&)
  tutor_stage__timer = get_sync_time() + tutor_stage__time

[es(no_order)]
def tutorial_stage_timer_es(info : UpdateStageInfoAct;
                            eid : EntityId;
                            tutor_stage__timer : float;
                            var tutor_stage__next : das_string&;
                            tutor_stage__timeoutTemplate : string = "")
  if tutor_stage__timer > info.curTime
    return

  if tutor_stage__timeoutTemplate != ""
    tutor_stage__next := tutor_stage__timeoutTemplate
  destroyEntity(eid)

[es(REQUIRE=hero)]
def tutorial_destroy_ri_target_es(evt : EventRendinstDestroyed;
                                  human_weap__currentGunEid : EntityId;
                                  human_anim__vehicleSelected : EntityId;
                                  human_attached_gun__attachedGunEid : EntityId)
  tutorial_hit_target_ri_process(find_ri_extra_eid(evt.riexHandle), human_weap__currentGunEid,
    human_anim__vehicleSelected, human_attached_gun__attachedGunEid)

[es(REQUIRE=hero)]
def tutorial_hit_ri_target_es(evt : CmdRendinstDamage;
                              human_weap__currentGunEid : EntityId;
                              human_anim__vehicleSelected : EntityId;
                              human_attached_gun__attachedGunEid : EntityId)
  tutorial_hit_target_ri_process(find_ri_extra_eid(evt.handle), human_weap__currentGunEid,
    human_anim__vehicleSelected, human_attached_gun__attachedGunEid)

[es(REQUIRE=(vehicle, dm_events), after=damage_model_es, track=dm_events, on_event=EventOnMetaPartDamage)]
def tutorial_hit_vehicle_target_es(evt : Event; tutorial_target__targetId : string; tutorial_target__active : bool)
  if !tutorial_target__active
    return

  query() <| $ [es] (eid : EntityId; tutor_stage__hitTarget : string; tutor_stage__hitTargetByWeapon : string = "")
    if tutorial_target__targetId != tutor_stage__hitTarget
      return

    query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId;
                                     human_anim__vehicleSelected : EntityId;
                                     human_attached_gun__attachedGunEid : EntityId)
      tutorial_hit_target_process(eid, tutor_stage__hitTargetByWeapon, human_weap__currentGunEid,
          human_anim__vehicleSelected, human_attached_gun__attachedGunEid)

[es(on_disappear)]
def tutorial_target_destroy_es(evt : Event; tutorial_target__targetId : string; tutorial_target__active : bool)
  if !tutorial_target__active
    return
  query() <| $ [es] (eid : EntityId; tutor_stage__hitTarget : string; tutor_stage__hitTargetByWeapon : string = "")
    if tutorial_target__targetId != tutor_stage__hitTarget
      return
    query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId;
                                     human_anim__vehicleSelected : EntityId;
                                     human_attached_gun__attachedGunEid : EntityId)
      tutorial_hit_target_process(eid, tutor_stage__hitTargetByWeapon, human_weap__currentGunEid,
        human_anim__vehicleSelected, human_attached_gun__attachedGunEid)

[es(no_order)]
def tutorial_zone_enter_es(info : UpdateStageInfoAct;
                           eid : EntityId;
                           tutor_stage__playerZoneEnter : string;
                           tutor_condition__zoneEnterOnVehicle : bool = false)
  query() <| $ [es(REQUIRE=hero)] (transform : float3x4;
                                   collres : CollisionResource;
                                   isInVehicle : bool;
                                   var tutorial_zone_visitor__zone : EntityId&;
                                   var tutorial_zone_visitor__zoneId : das_string&;
                                   human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID)
    if tutor_condition__zoneEnterOnVehicle && !isInVehicle
      return

    var tm = transform
    var box = BBox3(collres.vFullBBox)
    query(human_anim__vehicleSelected) <| $ [es] (collres : CollisionResource; transform : float3x4)
      box = BBox3(collres.vFullBBox)
      tm = transform

    query_active_tutorial_zone(tm, box, tutorial_zone_visitor__zone, tutorial_zone_visitor__zoneId)
    if tutor_stage__playerZoneEnter == string(tutorial_zone_visitor__zoneId)
      destroyEntity(eid)

[es(on_appear, REQUIRE=hero)]
def tutorial_on_hero_respawn_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_stage__onHeroRespawn)] (eid : EntityId)
    destroyEntity(eid)

[es(track=isAlive, REQUIRE=isAlive)]
def tutorial_destroy_target_es(evt : Event; tutorial_target__targetId : string; tutorial_target__active : bool)
  if !tutorial_target__active
    return

  find_query() <| $ [es] (eid : EntityId; tutor_stage__destroyTarget : string)
    if tutor_stage__destroyTarget != tutorial_target__targetId
      return false

    destroyEntity(eid)
    return true


[es(on_appear)]
def tutorial_damage_hero_es(evt : Event; eid : EntityId; tutor_action__damageHeroAmount : float)
  query() <| $ [es(REQUIRE=hero)] (var hitpoints__hp : float&)
    hitpoints__hp -= tutor_action__damageHeroAmount
    destroyEntity(eid)

[es(on_appear, tag=input)]
def tutorial_condition_hotkey_init(evt : Event; tutor_condition__hotKeyName : string; var tutor_condition__hotKeyId : int&)
  tutor_condition__hotKeyId = int(get_action_handle(tutor_condition__hotKeyName, TYPEGRP_DIGITAL));

[es(tag=input)]
def tutorial_condition_hotkey_release(evt : EventDaInputActionTriggered; eid : EntityId; tutor_condition__hotKeyId : int)
  if int(evt.action) != tutor_condition__hotKeyId
    return
  destroyEntity(eid)

[es(tag=gameClient, on_appear, before=tutorial_stage_skip_es)]
def tutorial_destroy_singleton(evt : Event; var tutor_action__destroySingletons : StringList)
  for singleton in tutor_action__destroySingletons
    string(singleton) |> getSingletonEntity |> destroyEntity

[es(on_appear, before=tutorial_stage_skip_es)]
def tutorial_create_entity_es(evt : Event; tutor_action__createEntity : StringList)
  for entity in tutor_action__createEntity
    createEntity(string(entity))

def private set_not_null(var obj : Object; name : string; val)
  if val != null
    obj |> set(name, *val)

[es(REQUIRE=tutorial__memorizeEntity, on_event=EventEntityDestroyed)]
def tutorial_memorize_entity_es(evt : Event;
                                eid : EntityId;
                                transform : float3x4;
                                tutorial_target__targetId : das_string const?;
                                tutorial_zone__zoneId : das_string const?;
                                tutorial_target__active : bool const?;
                                tutorial_zone__active : bool const?)
  query() <| $ [es] (var tutorial__memorizeEntities : Array)
    using() <| $(var obj : Object)
      obj |> set("template", getEntityTemplateName(eid))
      obj |> set("transform", transform)
      obj |> set_not_null("tutorial_target__targetId", tutorial_target__targetId)
      obj |> set_not_null("tutorial_zone__zoneId", tutorial_zone__zoneId)
      obj |> set_not_null("tutorial_target__active", tutorial_target__active)
      obj |> set_not_null("tutorial_zone__active", tutorial_zone__active)
      tutorial__memorizeEntities |> push(obj)

[es(REQUIRE=tutorial__restoreMemorize, on_appear)]
def tutorial_restore_memorize_es(evt : Event; eid : EntityId)
  query() <| $ [es] (var tutorial__memorizeEntities : Array&)
    for entity in tutorial__memorizeEntities
      let obj = entity |> get_ecs_object()
      let tmpl = obj |> get_ecs_string("template")
      if tmpl == null
        continue

      createEntity(string(*tmpl)) <| $(var init)
        init |> set("transform", *get_TMatrix(obj, "transform"))
        init |> set("tutorial_target__targetId", get_string(obj, "tutorial_target__targetId", ""))
        init |> set("tutorial_zone__zoneId", get_string(obj, "tutorial_zone__zoneId", ""))
        init |> set("tutorial_target__active", get_bool(obj, "tutorial_target__active") ?? false)
        init |> set("tutorial_zone__active", get_bool(obj, "tutorial_zone__active") ?? false)
    tutorial__memorizeEntities |> clear()
  destroyEntity(eid)

[es(on_event=CmdKickFromVehicle, REQUIRE=heroVehicle)]
def tutorial_on_vehicle_leave(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__playerVehicleEnter)] (eid : EntityId)
    destroyEntity(eid)

[es(tag=gameClient, no_order)]
def tutorial_time_speed_change_es(info : UpdateStageInfoAct;
                                  tutor_action__setTimeSpeed : float;
                                  tutor_action__timeSpeedDelta : float = 0.005;
                                  tutor_action__timeSpeedViscosity : float)
  let timeSpeed = approach(get_timespeed(), tutor_action__setTimeSpeed, tutor_action__timeSpeedDelta, tutor_action__timeSpeedViscosity)
  set_timespeed(timeSpeed)

[es(tag=server, REQUIRE=(hitpoints__hp, hero), track=hitpoints__hp)]
def tutorial_condition_hero_recv_dmg_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__heroRecvDamage)] (eid : EntityId)
    destroyEntity(eid)

[es(tag=server, REQUIRE=attachedToParent, track=(gun__ammo, gun__totalAmmo))]
def tutorial_condition_hero_out_of_ammo_es(evt : Event; eid : EntityId; gun__ammo : int; gun__totalAmmo : int; gun__owner : EntityId)
  query(gun__owner) <| $ [es(REQUIRE=hero)] (human_weap__gunEids : EidList; human_weap__curGunSlot : int)
    if human_weap__gunEids[human_weap__curGunSlot] == eid
      query() <| $ [es] (eid : EntityId; tutor_condition__totalAmmoLte : int)
        if gun__ammo + gun__totalAmmo <= tutor_condition__totalAmmoLte
          destroyEntity(eid)

[es(tag=server, on_appear)]
def tutorial_condition_hero_out_of_ammo_appear_es(evt : Event; eid : EntityId; tutor_condition__totalAmmoLte : int)
  query() <| $ [es(REQUIRE=hero)] (human_weap__gunEids : EidList; human_weap__curGunSlot : int)
    query(human_weap__gunEids[human_weap__curGunSlot]) <| $ [es] (gun__ammo : int; gun__totalAmmo : int)
      if gun__ammo + gun__totalAmmo <= tutor_condition__totalAmmoLte
        destroyEntity(eid)

[es(tag=server)]
def tutorial_condition_capture_point_es(evt : EventZoneCaptured;
                                        eid : EntityId;
                                        tutor_condition__captureTitle : string;
                                        tutor_condition__captureTeam : int = 1)
  if evt.team != tutor_condition__captureTeam
    return
  query(evt.zone) <| $ [es] (capzone__title : string)
    if capzone__title == tutor_condition__captureTitle
      destroyEntity(eid)

[es(tag=gameClient, track=squadFormationSpread)]
def tutorial_condition_formation_change_es(evt : Event; squadFormationSpread : int; is_local : bool)
  if !is_local
    return

  query() <| $ [es] (eid : EntityId; tutor_condition__squadFormation : int)
    if squadFormationSpread == tutor_condition__squadFormation
      destroyEntity(eid)

[es(tag=gameClient, on_appear)]
def tutorial_condition_formation_change_appear_es(evt : Event; eid : EntityId; tutor_condition__squadFormation : int)
  find_query() <| $ [es] (squadFormationSpread : int; is_local : bool)
    if is_local && squadFormationSpread == tutor_condition__squadFormation
      destroyEntity(eid)
      return true
    return false

[es(tag=gameClient, track=human_context_command__orderType, on_event=RqContextCommand)]
def tutorial_condition_context_cmd_es(evt : Event;
                                      human_context_command__orderType : int;
                                      human_context_command__orderPosition : float3)

  query() <| $ [es] (eid : EntityId; tutor_condition__orderType : int; tutor_condition__orderZoneId : string = "")
    if tutor_condition__orderType != human_context_command__orderType
      return

    if tutor_condition__orderZoneId == ""
      destroyEntity(eid)
      return

    find_query() <| $ [es] (tutorial_zone__zoneId : string; transform : float3x4)
      if tutorial_zone__zoneId != tutor_condition__orderZoneId
        return false

      if check_tutorial_zone(human_context_command__orderPosition, transform, int(ZoneCheck IN_ZONE))
        destroyEntity(eid)
        return true
      return false

[es(tag=server, REQUIRE=tutor_action__respawnMenu, on_appear)]
def tutorial_action_respawn_menu_es(evt : Event)
  query() <| $ [es] (eid : EntityId; squad__ownerPlayer : EntityId; squad__allMembers : EidList)
    query(squad__ownerPlayer) <| $ [es(REQUIRE_NOT=playerIsBot)] (var respawner__enabled : bool&)
      respawner__enabled = true
      for member in squad__allMembers
        destroyEntity(member)
      destroyEntity(eid)

[es(tag=server, on_appear)]
def tutorial_condition_soldier_in_squad_lte_appear_es(evt : Event; eid : EntityId; tutor_condition__soldierInSquadLte : int)
  var squadMemberCount = 0
  query() <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=heroSquad)] () { squadMemberCount++; }
  if squadMemberCount <= tutor_condition__soldierInSquadLte
    destroyEntity(eid)

[es(tag=server, on_appear, track=isAlive, REQUIRE=(isAlive, heroSquad, deadEntity))]
def tutorial_condition_soldier_in_squad_lte_es(evt : Event)
  query() <| $ [es] (eid : EntityId; tutor_condition__soldierInSquadLte : int)
    var squadMemberCount = 0
    query() <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=heroSquad)] () { squadMemberCount++; }
    if squadMemberCount <= tutor_condition__soldierInSquadLte
      destroyEntity(eid)

[es(track=pve_stage__enemyCount)]
def tutorial_pve_bot_die_es(evt : Event; pve_stage__name : string; pve_stage__enemyCount : int)
  if pve_stage__enemyCount <= 0
    query() <| $ [es] (eid : EntityId; var tutor_condition__botsKilled : StringList&)
      let idx = find_index(tutor_condition__botsKilled, pve_stage__name)
      if idx < 0
        return

      erase(tutor_condition__botsKilled, idx)
      if length(tutor_condition__botsKilled) == 0
        destroyEntity(eid)

[es(on_appear)]
def tutorial_pve_bot_die_init_es(evt : Event; eid : EntityId; var tutor_condition__botsKilled : StringList&)
  query() <| $ [es(REQUIRE_NOT=pve__active)] (pve_stage__name : string; pve_stage__enemyCount : int)
    if pve_stage__enemyCount > 0
      return

    let idx = find_index(tutor_condition__botsKilled, pve_stage__name)
    if idx < 0
      return
    erase(tutor_condition__botsKilled, idx)
  if length(tutor_condition__botsKilled) == 0
    destroyEntity(eid)

[es(on_appear)]
def tutorial_activate_pve_stage(evt : Event; tutor_action__spawnBots : StringList)
  query() <| $ [es(REQUIRE_NOT=pve__active)] (eid : EntityId; pve_stage__name : string; var pve_stage__enemyCount : int&)
    if find_index(tutor_action__spawnBots, pve_stage__name) >= 0
      addSubTemplate(eid, "pve_active")
      pve_stage__enemyCount = 0


[es(on_appear, REQUIRE=tutor_stage__skip)]
def tutorial_stage_skip_es(evt : Event; eid : EntityId)
  destroyEntity(eid)


[es(on_appear)]
def tutorial_destroy_not_exist_target_es(evt : Event; eid : EntityId; tutor_stage__hitTarget : string)
  let found = find_query() <| $ [es] (tutorial_target__targetId : string)
    return tutorial_target__targetId == tutor_stage__hitTarget
  if !found
    destroyEntity(eid)
