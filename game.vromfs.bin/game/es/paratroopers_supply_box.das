require ecs
require ecs.safe
require ecs.common
require game.es.paratroopers_supply_box_common
require game.es.events
require game.events_game
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require game.es.spawn_soldier_common
require game.es.action_common
require HumanPhys
require DngNet
require DngPhysObj
require DngHuman
require DngDm
require DagorMath

[es(tag=server, no_order)]
def kick_supply_box_from_paratroopers_plane(info : UpdateStageInfoAct;
                                            transform : float3x4;
                                            paratroopers_aircraft__respawnerEid : EntityId;
                                            paratroopers_aircraft__supplyBoxTemplate : string;
                                            paratroopers_aircraft__supplyBoxSpawnOffset : float3;
                                            paratroopers_aircraft__supplyBoxSquad : EntityId;
                                            net_phys__currentStateVelocity : float3;
                                            var paratroopers_aircraft__wasSupplyBoxSpawned : bool&;
                                            var paratroopers_aircraft__kickSupplyBoxAtTime : float&)
  if !paratroopers_aircraft__wasSupplyBoxSpawned && paratroopers_aircraft__kickSupplyBoxAtTime > 0. && info.curTime > paratroopers_aircraft__kickSupplyBoxAtTime
    query(paratroopers_aircraft__respawnerEid) <| $ [es] (respawner__paratroopersPointCoords : float3)
      spawn_supply_box(paratroopers_aircraft__supplyBoxTemplate,
                      transform * paratroopers_aircraft__supplyBoxSpawnOffset,
                      paratroopers_aircraft__supplyBoxSquad,
                      net_phys__currentStateVelocity,
                      respawner__paratroopersPointCoords.xz)
      paratroopers_aircraft__kickSupplyBoxAtTime = -1.
      paratroopers_aircraft__wasSupplyBoxSpawned = true

[es(tag=server, on_appear)]
def set_squad_for_paratroopers_supply_box(evt : Event; eid : EntityId; squad__ownerPlayer : EntityId)
  find_query() <| $ [es] (paratroopers_aircraft__respawnerEid : EntityId; var paratroopers_aircraft__supplyBoxSquad : EntityId&)
    if squad__ownerPlayer == paratroopers_aircraft__respawnerEid
      paratroopers_aircraft__supplyBoxSquad = eid
      return true
    return false

[es(on_appear)]
def supply_box_init_speed(evt : Event;
                          supply_box__initVel : float3;
                          var phys_obj_net_phys : PhysObjActor;
                          var horizontal_air_resistance__isOn : bool&)
  horizontal_air_resistance__isOn = true
  phys_obj_net_phys.phys.currentState.velocity = supply_box__initVel
  phys_obj_net_phys.phys.previousState.velocity = supply_box__initVel

[es(tag=ui, on_appear, before=useful_boxes_markers_es)]
def supply_box_init_marker(evt : Event;
                           supply_box__squad : EntityId;
                           var map_icon__visibleToSquad : EntityId&;
                           var hud_icon__visibleToSquad : EntityId&)
  map_icon__visibleToSquad = supply_box__squad
  hud_icon__visibleToSquad = supply_box__squad

[es(tag=ui, on_appear, track=supply_box__isActive)]
def supply_box_toggle_marker_active(evt : Event;
                                    supply_box__isActive : bool;
                                    var hud_icon__isActive : bool&;
                                    var map_icon__isActive : bool&)
  hud_icon__isActive = supply_box__isActive
  map_icon__isActive = supply_box__isActive


def create_inventory(member : EntityId; inventory : Array const?)
  if inventory == null
    return

  for it in *inventory
    let itemTemplate = (it as Object)?.gametemplate ?? ""
    if !empty(itemTemplate)
      let finalizeCreation <- @ <| (itemEid : EntityId)
        query(member) <| $ [es] (var itemContainer : EidList)
          if find_index(itemContainer, itemEid) < 0
            itemContainer |> push(itemEid)

      createEntity(itemTemplate, finalizeCreation) <| $(var init : ComponentsInitializer)
        set(init, "item__lastOwner", member)
        set(init, "item__ownerEid", member)

def create_weapons(member : EntityId; preset : Object)
  let weapTemplates = preset.human_weap__weapTemplates ?as Object
  if weapTemplates == null
    return

  let weaponsInfo = preset.human_weap__weapInfo ?as Array
  let weaponsComps = preset.human_weap__weapInitialComponents ?as Array

  query(member) <| $ [es] (var human_weap__weapTemplates : Object;
                           var human_weap__weapInfo : Array&;
                           var human_weap__weapInitialComponents : Array&)
    for slot in range(int(HUWeaponSlots EWS_NUM))
      let slotName = get_human_weapon_slot_name(slot)
      let weapTempl = weapTemplates?[slotName] ?? ""
      if !empty(weapTempl)
        human_weap__weapTemplates |> set(slotName, weapTempl)
        let weapInfo = weaponsInfo?[slot] ?as Object
        if weapInfo != null
          human_weap__weapInfo[slot] |> set(*weapInfo)
        let initComps = weaponsComps?[slot] ?as Object
        if initComps != null
          human_weap__weapInitialComponents[slot] |> set(*initComps)
        sendEvent(member, [[CmdReinitWeaponInSlot slot=slot]])

def create_equipment(member : EntityId; preset : Object)
  let equipment = preset.equipment ?as Object
  if equipment == null
    return
  for kv in *equipment
    let item = kv.value as Object
    let gametempate = item?.gametemplate ?? ""
    let slot = item?.slot ?? ""
    if empty(gametempate) || empty(slot)
      continue
    let addTemplate = get_item_sub_template(gametempate, slot)
    let itemTemplate = empty(addTemplate) ? gametempate : "{gametempate}+{addTemplate}"
    let finalizeCreation <- @ <| (itemEid : EntityId)
      sendEventImmediate(member, [[CmdEquipItemDirect itemEid=itemEid, slot=slot, allowReorderSlots=false, dropPrevItem=true]])

    createEntity(itemTemplate, finalizeCreation) <| $ [unused_argument(init)] (var init) {}

def set_kind_icon(member : EntityId; preset : Object)
  let displayedKind = preset.displayedKind ?? ""
  if empty(displayedKind)
    return
  query(member) <| $ [es] (var soldier__displayedKind : das_string&)
    soldier__displayedKind := displayedKind

def apply_soldier_preset(member : EntityId; preset : Object)
  create_inventory(member, preset.inventory ?as Array)
  create_weapons(member, preset)
  create_equipment(member, preset)
  set_kind_icon(member, preset)

def try_apply_squad_preset(squad : EntityId; preset_id : int)
  var wasApplied = false
  query() <| $ [es] (paratroopers__supplySchemes : Object)
    query(squad) <| $ [es] (squad__allMembers : EidList; squad__squadProfileId : string; squad__leader : EntityId)
      var presets = paratroopers__supplySchemes[squad__squadProfileId] ?as Array
      if presets == null
        presets = paratroopers__supplySchemes.default ?as Array
      let preset = presets?[preset_id] ?as Object
      let soldierPresets = preset?.soldiers ?as Array
      if soldierPresets == null
        return
      var currentSoldierPreset = 0
      let soldierPresetCount = length(*soldierPresets)
      let members <- get_sorted_squad_members(squad__allMembers, squad__leader)
      for member in members
        if currentSoldierPreset >= soldierPresetCount
          break
        let soldierPreset = soldierPresets?[currentSoldierPreset] ?as Object
        if soldierPreset != null
          apply_soldier_preset(member.eid, *soldierPreset)
        currentSoldierPreset++
      wasApplied = true
  return wasApplied

def get_sorted_squad_members(members : EidList; leader : EntityId)
  let leaderIndex = leader |> get_int("squad_member__memberIdx") ?? 0
  var res : array<tuple<index : int; eid : EntityId>>
  let membersCount = length(members)
  for member in members
    query(member) <| $ [es(REQUIRE_NOT=deadEntity)] (squad_member__memberIdx : int)
      let index = (membersCount + squad_member__memberIdx - leaderIndex) % membersCount
      res |> push([[auto index, member]])
  sort(res) <| $(a, b) => a.index < b.index
  return <- res

def validate_box(box : EntityId; soldier : EntityId)
  var isValid = false
  query(soldier) <| $ [es] (transform aka soldier_transform : float3x4;
                            squad_member__squad : EntityId)
    query(box) <| $ [es] (supply_box__isActive : bool;
                          supply_box__squad : EntityId;
                          supply_box__maxUseDistSq : float;
                          transform aka box_transform : float3x4)
      isValid = (supply_box__isActive
              && supply_box__squad == squad_member__squad
              && distance_sq(box_transform[3], soldier_transform[3]) < supply_box__maxUseDistSq)
  return isValid

[es(tag=server)]
def apply_paratroopers_supply_scheme_request(evt : RequestApplySupplyScheme; possessed : EntityId; respawner__squad : EntityId)
  query(evt.boxEid) <| $ [es] (var supply_box__isActive : bool&)
    if !validate_box(evt.boxEid, possessed)
      return
    if try_apply_squad_preset(respawner__squad, evt.index)
      supply_box__isActive = false

[es(tag=gameClient, on_event=RequestApplySupplyScheme, REQUIRE=localPlayer)]
def paratroopers_supply_box_use_feedback(evt : Event; possessed : EntityId)
  broadcastEvent([[CmdShowAllWeaponsUi]])
  run_action(possessed, "pickup")

[es(tag=server, on_appear)]
def paratroopers_init_supply_box_description(evt : Event; supply_box__squad : EntityId)
  query(supply_box__squad) <| $ [es] (squad__squadProfileId : string; squad__ownerPlayer : EntityId)
    query(squad__ownerPlayer) <| $ [es] (respawner__squad : EntityId; var respawner__paratroopersSupplySlotsInfo : Array&)
      if respawner__squad != supply_box__squad // not current squad
        return
      query() <| $ [es] (paratroopers__supplySchemes : Object)
        respawner__paratroopersSupplySlotsInfo |> clear()
        var presets = paratroopers__supplySchemes[squad__squadProfileId] ?as Array
        if presets == null
          presets = paratroopers__supplySchemes.default ?as Array
        if presets == null
          return
        for it in *presets
          let preset = it as Object
          push_to_array(respawner__paratroopersSupplySlotsInfo) <| $(var desc : Object)
            desc |> set("text", preset?.name ?? "")

[es(tag=server, on_disappear, REQUIRE=hasParachute)]
def paratroopers_supply_box_landing_init_timer(evt : Event;
                                               supply_box__landingTime : float;
                                               var supply_box__landingTimer : float&)
  supply_box__landingTimer = supply_box__landingTime

[es(tag=server, REQUIRE_NOT=hasParachute)]
def paratroopers_supply_box_landing(upd : CmdPostPhysUpdate;
                                    human_parachute__eid : EntityId;
                                    phys_obj_net_phys : PhysObjActor;
                                    supply_box__landingSpeedSq : float = 1.0;
                                    supply_box__landingOmegaSq : float = 0.3;
                                    var supply_box__landingTimer : float&;
                                    var supply_box__hasLanded : bool&)
  assume omega = phys_obj_net_phys.phys.currentState.omega
  assume velocity = phys_obj_net_phys.phys.currentState.velocity
  if (supply_box__landingTimer < 0.
      || !!human_parachute__eid
      || supply_box__hasLanded
      || length_sq(velocity) > supply_box__landingSpeedSq
      || length_sq(omega) > supply_box__landingOmegaSq)
    return
  supply_box__landingTimer -= upd.dt
  if supply_box__landingTimer <= 0.
    supply_box__hasLanded = true

[es(tag=server, track=supply_box__hasLanded)]
def paratroopers_supply_box_recreate_after_landing(evt : Event;
                                                   eid : EntityId;
                                                   supply_box__hasLanded : bool;
                                                   supply_box__deployedTemplate : string)
  if supply_box__hasLanded
    remote_recreate_entity_from(eid, supply_box__deployedTemplate)

[es(tag=server)]
def supply_box_human_collision_damage(evt : EventOnCollision;
                                      transform : float3x4;
                                      supply_box__collisionDamageMinVelocity : float;
                                      supply_box__collisionDamageLethalVelocity : float)
  query(evt.offender) <| $ [es(REQUIRE=human)] (hitpoints__maxHp : float)
    let lethalK = safediv(length(evt.cvel) - supply_box__collisionDamageMinVelocity,
                          supply_box__collisionDamageLethalVelocity - supply_box__collisionDamageMinVelocity)
    let damage = max(0.0, lethalK) * hitpoints__maxHp
    if damage > 0.0
      let dmDesc = DamageDesc(DamageType DM_COLLISION, damage, transform[3])
      damage_entity(evt.offender, INVALID_ENTITY_ID, dmDesc)
