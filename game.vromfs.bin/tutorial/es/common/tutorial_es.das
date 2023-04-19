require dm
require ecs
require ecs.common
require app
require player
require CollRes
require RendInst
require DagorMath
require DmFire
require DngDm
require DagorSystem
require DagorInput
require DngActor
require game.events_game
require game.utils.team
require game.es.vehicle.vehicle_events
require enlisted.tutorial.tutorial_events
require enlisted.tutorial.tutorial_common
require game.es.input.input_events
require enlisted.events_enlisted
require common_shooter.es.vehicle.vehicle_damage_common

def tutorial_rendinst_damaged(ri_eid; gun_eid; vehicle_selected)
  query(ri_eid) <| $ [es(REQUIRE=tutorialTarget)] (tutorial_target__active : bool = true)
    if !tutorial_target__active
      return
    var weaponType = ""
    query(vehicle_selected) <| $ [es] (vehicle_seats__enumVarName : string)
      weaponType = vehicle_seats__enumVarName
    if weaponType == "" && !vehicle_selected
      let currentGunEid = gun_eid
      query(currentGunEid) <| $ [es] (item__weapType : string)
        weaponType = item__weapType
      weaponType = has(currentGunEid, "grenade_thrower") ? "grenade" : weaponType
    sendEvent(ri_eid, [[CmdTutorialTargetDamaged weaponType=weaponType]])

[es(REQUIRE=hero, REQUIRE_NOT=tutorialHuman, on_appear)]
def tutorial_human_init(evt : Event; eid : EntityId)
  addSubTemplate(eid, "tutorial_human")
  query() <| $ [es(REQUIRE=useful_box__useCount)] (var buildByPlayer : EntityId&)
    buildByPlayer = eid

[es(no_order, REQUIRE=hero)]
def tutorial_zone_enter(info : UpdateStageInfoAct;
                        transform : float3x4;
                        collres : CollisionResource;
                        var tutorial_zone_visitor__zone : EntityId&;
                        var tutorial_zone_visitor__zoneId : das_string&;
                        human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID)
  var tm = transform
  var box = BBox3(collres.vFullBBox)
  query(human_anim__vehicleSelected) <| $ [es] (collres : CollisionResource; transform : float3x4)
    box = BBox3(collres.vFullBBox)
    tm = transform
  query_active_tutorial_zone(tm, box, tutorial_zone_visitor__zone, tutorial_zone_visitor__zoneId)

[es(REQUIRE=hero)]
def tutorial_rendinst_destroyed_es(evt : EventRendinstDestroyed;
                                   human_weap__currentGunEid : EntityId;
                                   human_anim__vehicleSelected : EntityId)
  let riExtraEid = find_ri_extra_eid(evt.riexHandle)
  tutorial_rendinst_damaged(riExtraEid, human_weap__currentGunEid, human_anim__vehicleSelected)

[es(tag=gameClient, REQUIRE=hero)]
def tutorial_rendinst_projectile_damage_target_es(evt : CmdRendinstDamage;
                                                  human_weap__currentGunEid : EntityId;
                                                  human_anim__vehicleSelected : EntityId)
  let riExtraEid = find_ri_extra_eid(evt.handle)
  tutorial_rendinst_damaged(riExtraEid, human_weap__currentGunEid, human_anim__vehicleSelected)

[es(tag=gameClient, track=(hitpoints__hp, isAlive), after=hitpoints_es, before=track_is_alive, REQUIRE=tutorial__infinityHp)]
def tutorial_human_infinity_hp_es(evt : Event;
                                  eid : EntityId;
                                  hitpoints__maxHp : float;
                                  isAlive : bool;
                                  var hitpoints__hp : float&;
                                  tutorial_human__infHpLimit : float const?;
                                  isOutsideBattleArea : bool = true)
  let hp = tutorial_human__infHpLimit ?? hitpoints__maxHp
  if !has(eid, "heroSquad")
    hitpoints__hp = hp
    return

  if !isOutsideBattleArea
    hitpoints__hp = hp
  if hitpoints__hp <= 0.f || !isAlive
    sendEvent(get_local_player_eid(), [[CmdSwitchSquad]])

[es(tag=gameClient, after=damage_model_es)]
def tutorial_vehicle_fire_protect_es(info : UpdateStageInfoAct;
                                     var damage_model : DamageModel&;
                                     var fire_protection : FireProtection&)
  for part in damage_model.dmData.parts
    let partId = get_damage_part_id(part)
    assume fire_protection_part = fire_protection[partId]
    fire_protection_part.hpFixed = uint16(MAX_REL_HP_FIXED)

[es(tag=gameClient, REQUIRE=player)]
def tutorial_show_squad_menu_es(evt : CmdSwitchSquad)
  tutorial_squad_change()

[es(tag=gameClient)]
def tutorial_vehicle_damage_effect_es(evt : CmdTutorialDamageVehiclePart;
                                      eid : EntityId;
                                      fire_damage__fireParamsPreset : string;
                                      var damage_model : DamageModel&;
                                      var fire_damage__isBurn : bool&;
                                      var fire_damage__gunPropsId : int&;
                                      var fire_damage__shellId : int&;
                                      var fire_damage : FireDamageComponent&)
  if evt.partId < 0
    logerr("CmdTutorialTargetDamaged partId is not specify")
    return
  if evt.damageMask == int(DamageEffectType DM_EFFECT_FIRE)
    vehicle_start_burn_part(eid, evt.partId, INVALID_ENTITY_ID, -1, -1, damage_model, fire_damage__fireParamsPreset, fire_damage__isBurn,
                            fire_damage__gunPropsId, fire_damage__shellId, fire_damage)
  else
    deal_damage_to_part(damage_model, eid, evt.partId, 0, int(DamageEffectsMask DM_EFFECTS_MASK_ALL), get_max_hp(damage_model.dmData, evt.partId), HitData())

[es(REQUIRE=hero, REQUIRE_NOT=tutorial__infinityHp, on_appear)]
def tutorial_hero_infinity_hp_es(evt : Event; eid : EntityId)
  addSubTemplate(eid, "tutorial_infinity_hp")

[es(REQUIRE=heroSquad, REQUIRE=tutorial__infinityHp, on_disappear)]
def tutorial_hero_squad_remove_infinity_hp_es(evt : Event; eid : EntityId)
  removeSubTemplate(eid, "tutorial_infinity_hp")

[es(tag=input, on_appear)]
def tutorial_press_key_init_es(evt : Event; tutor_condition__pressKey : StringList; var tutor_condition__pressKeyCode : IntList&)
  for _ in tutor_condition__pressKey
    tutor_condition__pressKeyCode |> push(int(get_action_handle("Vehicle.NextBulletType", TYPEGRP_DIGITAL)))

[es(tag=input)]
def tutorial_press_key_process_es(evt : EventDaInputActionTriggered; eid : EntityId; tutor_condition__pressKeyCode : IntList)
  if tutor_condition__pressKeyCode |> find_index(int(evt.action)) >= 0
    destroyEntity(eid)

[es(tag=server, on_appear, track=human_weap__curGunSlot, REQUIRE=watchedByPlr)]
def tutorial_check_cur_gun_component_on_weapon_switch_es(evt : Event; human_weap__curGunSlot : int; human_weap__gunEids : EidList)
  query() <| $ [es] (eid : EntityId; tutor_stage__curGunComponentAny : StringList)
    for component in tutor_stage__curGunComponentAny
      let compStr = string(component)
      if has(human_weap__gunEids[human_weap__curGunSlot], compStr, ecs_hash(compStr))
        destroyEntity(eid)

[es(tag=server, on_appear)]
def tutorial_check_cur_gun_component_es(evt : Event; eid : EntityId; tutor_stage__curGunComponentAny : StringList)
  query() <| $ [es(REQUIRE=watchedByPlr)] (human_weap__curGunSlot : int; human_weap__gunEids : EidList)
    for component in tutor_stage__curGunComponentAny
      let compStr = string(component)
      if has(human_weap__gunEids[human_weap__curGunSlot], compStr, ecs_hash(compStr))
        destroyEntity(eid)
