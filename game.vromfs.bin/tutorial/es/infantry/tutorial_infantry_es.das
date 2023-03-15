require ecs
require dm
require app
require player
require HumanPhys
require EnlistedHuman
require AnimV20
require math.base
require EnlistedActor
require EnlistedPhysObj
require game.es.events
require common_shooter.events_common_shooter
require game.utils.hero
require game.utils.team
require common_shooter.es.squad_common
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require enlisted.tutorial.tutorial_events
require enlisted.tutorial.tutorial_common
require ecs.common
require enlisted.game.es.client.tutorial_bq_common

enum TutorialStage : int
  NONE = 0


let
  SPAWN_ANGLES = [[float[] 0f; 60f; -60f; 180f]]


def calc_offset(index : int; spread : float)
  var s, c : float
  let angle = index < length(SPAWN_ANGLES) ? SPAWN_ANGLES[index] : 0f
  sincos(deg_to_rad(angle), s, c)
  return float3(c, 0f, s) * spread


def activate_target_grenade_resupply_zone()
  tutorial_hint("tutorial_hint", "tutorial_hint", "hint_tutorial_grenade_resupply")
  set_tutorial_zone_active("target_grenade_expl_zone", false)
  set_tutorial_zone_active("target_grenade_resupply_zone", true)

def has_grenade(itemContainer)
  for item in itemContainer
    if has(item, "item__grenadeType")
      return true
  return false

[es(tag=gameClient, REQUIRE=shell__owner, after=tutorial_target_destroy_es)]
def tutorial_grenade_exploded_in_zone_es(evt : CmdShellExplode)
  query() <| $ [es] (eid : EntityId; tutor_condition__explodedInZone : string)
    var zoneId : string = ""
    var zoneEid : EntityId = INVALID_ENTITY_ID
    query_active_tutorial_zone(evt.position, zoneEid, zoneId)
    if tutor_condition__explodedInZone == zoneId
      destroyEntity(eid)

[es(on_disappear, REQUIRE=tutorial_target__grenade)]
def grenade_target_destroy_es(evt : Event; tutorial_target__targetId : string)
  query() <| $ [es] (eid : EntityId; tutor_stage__hitTarget : string; tutor_stage__hitTargetByWeapon : string)
    if tutorial_target__targetId == tutor_stage__hitTarget && tutor_stage__hitTargetByWeapon == "grenade"
      destroyEntity(eid)

[es(tag=gameClient, after=(tutorial_target_destroy_es, tutorial_grenade_exploded_in_zone_es))]
def tutorial_grenade_ressuply_observer_explode_es(evt : CmdShellExplode; eid : EntityId; shell__owner : EntityId)
  let currentShellEid = eid

  let grenadeObserver = find_query() <| $ [es(REQUIRE=tutorial_observer__grenade_count)] () { return true; }
  if !grenadeObserver
    return

  query(shell__owner) <| $ [es] (itemContainer : EidList; var tutorial_human__hasGrenade : bool&)
    if has_grenade(itemContainer)
      return

    let ownerEid = shell__owner
    let foundGrenade = find_query() <| $ [es] (eid : EntityId; shell__owner : EntityId)
      return currentShellEid != eid && shell__owner == ownerEid

    if foundGrenade
      return

    activate_target_grenade_resupply_zone()
    tutorial_human__hasGrenade = false


[es(tag=gameClient, track=tutorial_zone__active)]
def tutorial_grenade_resupply_observer_zone_activate(evt : Event;
                                                     tutorial_zone__active : bool;
                                                     tutorial_zone__zoneId : string)
  if !tutorial_zone__active
    return

  let grenadeObserver = find_query() <| $ [es(REQUIRE=tutorial_observer__grenade_count)] (tutorial_observer__resupplyGrenadesOnActivatingZones : StringList)
    return find_index(tutorial_observer__resupplyGrenadesOnActivatingZones, tutorial_zone__zoneId) > -1
  if !grenadeObserver
    return

  query() <| $ [es(REQUIRE=hero)] (itemContainer : EidList;
                                   var tutorial_human__hasGrenade : bool&)
    if has_grenade(itemContainer)
      return

    activate_target_grenade_resupply_zone()
    tutorial_human__hasGrenade = false


[es(tag=gameClient, track=itemContainer)]
def tutorial_grenade_ressuply_observer_es(evt : Event; itemContainer : EidList; var tutorial_human__hasGrenade : bool&)
  query() <| $ [es(REQUIRE=tutorial_observer__grenade_count)] (tutorial_observer__restartFromStage : string)
    let hasGrenade = has_grenade(itemContainer)
    if hasGrenade && tutorial_human__hasGrenade != hasGrenade
      query() <| $ [es] (eid : EntityId; var tutor_stage__next : das_string&)
        tutor_stage__next := tutorial_observer__restartFromStage
        set_tutorial_zone_active("target_grenade_resupply_zone", false)
        destroyEntity(eid)
    tutorial_human__hasGrenade = hasGrenade

[es(tag=gameClient, track=possessedByPlr, on_appear, on_event=EventComponentsDisappear, REQUIRE=heroSquad, REQUIRE_NOT=(hero, tutorial_bot_anim_state), before=before_net_phys_sync)]
def tutorial_lock_bot_at_point_es(evt : Event;
                                  eid : EntityId;
                                  squad_member__memberIdx : int;
                                  possessedByPlr : EntityId;
                                  var human_net_phys : HumanActor&;
                                  var transform aka bot_transform : float3x4;
                                  var beh_tree__enabled : bool&)
  if !!possessedByPlr
    return
  query() <| $ [es(REQUIRE=tutorial__botSpawnBase)] (transform : float3x4)
    let spreadAroundOrderPoint = 1.2
    let offset = calc_offset(squad_member__memberIdx, spreadAroundOrderPoint)
    bot_transform[3] = find_best_squad_pos(transform, offset, spreadAroundOrderPoint)
    beh_tree__enabled = false
    human_net_phys.phys.producedCT |> human_control_state_set_walk_dir(float2(0, 0))
    human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots EWS_PRIMARY)
    human_net_phys.phys.currentState.weapEquipState.curSlot = HUWeaponSlots EWS_PRIMARY
    teleport_phys_actor(eid, bot_transform)
  addSubTemplate(eid, "tutorial_bot_anim_state")

[es(tag=gameClient, on_appear, REQUIRE=tutorial_bot_anim_state)]
def tutorial_bot_anim_state_init_es(evt : Event;
                                    eid : EntityId;
                                    animchar : AnimcharBaseComponent;
                                    game_effect__forceAnimState : string;
                                    var game_effect__attachedTo : EntityId&;
                                    var game_effect__forceAnimStateId : int&)
  tutorial_stage_action(TutorialStage NONE) <| $()
    game_effect__attachedTo = eid
    let animGraph = animchar.animGraph
    if animGraph != null
      game_effect__forceAnimStateId = anim_graph_getStateIdx(*animGraph, game_effect__forceAnimState)


def activate_target_ammo_resupply_zone()
  tutorial_hint("tutorial_hint", "tutorial_hint", "hint_tutorial_ammo_resupply")
  set_tutorial_zone_active("target_grenade_resupply_zone", true)


def activate_target_shoot_zone()
  if is_tutorial_zone_active("target01_marker_zone")
    tutorial_hint("tutorial_hint", "tutorial_hint", "hint_tutorial_fire_range_practice01", "Human.Shoot")
  elif is_tutorial_zone_active("target02_marker_zone")
    tutorial_hint("tutorial_hint", "tutorial_hint", "hint_tutorial_fire_range_aim", "Human.Aim1")
  set_tutorial_zone_active("target_grenade_resupply_zone", false)


def get_max_total_ammo_for_gun(gun__owner : EntityId; gun__maxAmmo : int)
  var numReserveAmmo = 0
  ecs::query(gun__owner) <| $ [es(REQUIRE=watchedByPlr)] (human_weap__weapInfo : ecs::Array;
                                                          human_weap__currentGunSlot : int)
    if human_weap__currentGunSlot > -1 && human_weap__currentGunSlot < length(human_weap__weapInfo)
      let weapInfo = get_ecs_object(human_weap__weapInfo[int(human_weap__currentGunSlot)])
      numReserveAmmo = get_int(weapInfo, "numReserveAmmo") ?? 0
  return numReserveAmmo * gun__maxAmmo


def hint_on_out_of_ammo(gun__owner : EntityId; gun__ammo : int; gun__maxAmmo : int; gun__totalAmmo : int)
  if is_tutorial_zone_active("target01_marker_zone") || is_tutorial_zone_active("target02_marker_zone")
    if gun__ammo == 0 && gun__totalAmmo == 0
      activate_target_ammo_resupply_zone()
    elif gun__totalAmmo == get_max_total_ammo_for_gun(gun__owner, gun__maxAmmo)
      activate_target_shoot_zone()

[es(tag=gameClient, track=tutorial_zone_visitor__zoneId, REQUIRE=tutorial_zone_visitor__zoneId)]
def tutorial_hint_on_switch_zone_without_ammo(evt : Event)
  query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId)
    query(human_weap__currentGunEid) <| $ [es] (gun__owner : EntityId; gun__ammo : int; gun__maxAmmo : int; gun__totalAmmo : int)
      hint_on_out_of_ammo(gun__owner, gun__ammo, gun__maxAmmo, gun__totalAmmo)

[es(tag=gameClient, track=(gun__ammo, gun__totalAmmo))]
def tutorial_hint_on_out_of_ammo(evt : Event; gun__owner : EntityId; gun__ammo : int; gun__maxAmmo : int; gun__totalAmmo : int)
  query() <| $ [es(REQUIRE=watchedByPlr)] ()
    hint_on_out_of_ammo(gun__owner, gun__ammo, gun__maxAmmo, gun__totalAmmo)

[es(REQUIRE=tutorial_lock_soldier_change, on_event=EventEntityDestroyed)]
def tutorial_soldier_change_unlock_es(evt : Event)
  find_query() <| $ [es(REQUIRE=hero)] (eid aka hero_eid : EntityId; var squad_member__squad : EntityId&)
    find_query() <| $ [es] (eid : EntityId; squad__leader : EntityId)
      if hero_eid != squad__leader
        return false
      squad_member__squad = eid
      return true
    return true

[es(REQUIRE=tutorial_lock_soldier_change, on_event=EventEntityCreated)]
def tutorial_soldier_change_lock_es(evt : Event)
  query(get_controlled_hero()) <| $ [es] (var squad_member__squad : EntityId&)
    squad_member__squad = INVALID_ENTITY_ID

[es(REQUIRE=hero, on_appear, after=init_hero_squad_components)]
def tutorial_reset_hero_squad_es(evt : Event; var squad_member__squad : EntityId&)
  query() <| $ [es(REQUIRE=tutorial_lock_soldier_change)] ()
    squad_member__squad = INVALID_ENTITY_ID

[es(track=possessedByPlr, REQUIRE=human, REQUIRE=possessedByPlr)]
def tutor_change_gunner_es(evt : Event; eid : EntityId; human_weap__gunEids : EidList)
  let possessedEid = eid
  query() <| $ [es(REQUIRE=tutor_stage__changeGunner)] (eid : EntityId;
                                                        tutor_stage__requireWeapon : string)
    for gunEid in human_weap__gunEids
      query(gunEid) <| $ [es] (item__weapType : string)
        if item__weapType != tutor_stage__requireWeapon
          return
        query() <| $ [es] (var respawner__respRequestedMemberId : int&)
          respawner__respRequestedMemberId = 1
        set_tutorial_stage(TutorialStage NONE)
        destroyEntity(eid)
    removeSubTemplate(possessedEid, "tutorial_bot_anim_state")

[es(REQUIRE=item__healAnimEnumValue, on_event=EventEntityDestroyed)]
def tutor_use_medkit_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_stage__useMedkit)] (eid : EntityId)
    destroyEntity(eid)

[es(on_appear, before=tutorial_action_hero_explode_es)]
def tutorial_action_set_hero_limit_inf_hp_es(evt : Event; tutor_action__setHeroInfHpLimit : float)
  query() <| $ [es(REQUIRE=hero)] (var tutorial_human__infHpLimit : float&)
    tutorial_human__infHpLimit = tutor_action__setHeroInfHpLimit

[es(tag=gameClient, on_appear, REQUIRE=respawner__enabled, track=respawner__enabled)]
def tutorial_destroy_squad_es(evt : Event; eid : EntityId; respawner__enabled : bool)
  if !respawner__enabled
    return

  let playerEid = eid
  query() <| $ [es] (eid : EntityId; squad__ownerPlayer : EntityId; squad__allMembers : EidList)
    if playerEid != squad__ownerPlayer
      return
    for member in squad__allMembers
      destroyEntity(member)
    destroyEntity(eid)

[es(on_event=(EventEntityDestroyed), REQUIRE=squad__ownerPlayer)]
def tutorial_respawn_squad_es(evt : Event)
  spawn_squad_immediate()

[es(tag=server, no_order, REQUIRE=grenade__selectedWeaponVar)]
def tutorial_grenade_throw_es(info : UpdateStageInfoAct; transform : float3x4; phys_obj_net_phys : PhysObjActor)
  let vel = phys_obj_net_phys.phys.currentState.velocity
  if length_sq(vel) > 1E-4
    return
  query() <| $ [es] (eid : EntityId; tutor_condition__grenadeStopInZone : string)
    var zoneId : string = ""
    var zoneEid : EntityId = INVALID_ENTITY_ID
    query_active_tutorial_zone(transform[3], zoneEid, zoneId)
    if tutor_condition__grenadeStopInZone == zoneId
      destroyEntity(eid)
