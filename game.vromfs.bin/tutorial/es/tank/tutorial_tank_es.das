require ecs
require dm
require AnimV20
require ecs.common
require game.es.events
require enlisted.tutorial.tutorial_events
require common_shooter.events_common_shooter

[es(on_appear, REQUIRE=tutor_action__tankTrackDestroy)]
def tutorial_tank_destroy_track_es(evt : Event; eid : EntityId)
  query() <| $ [es] (eid : EntityId; dm_phys_parts__tracksPartIds : IntList)
    for partId in dm_phys_parts__tracksPartIds
      sendEvent(eid, [[CmdTutorialDamageVehiclePart partId=partId, damageMask=int(DamageEffectsMask DM_EFFECTS_MASK_ALL)]])
  destroyEntity(eid)

[es(REQUIRE=vehicle, on_event=EventOnRepaired)]
def tutorial_tank_vehicle_repaired(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__tankRepairVehicle)] (eid : EntityId)
    destroyEntity(eid)

[es(on_event=EventEnterVehicle, REQUIRE=(hero, tutorialHuman))]
def tutorial_on_vehicle_enter(evt : Event)
  query() <| $ [es(REQUIRE=tutor_stage__playerVehicleEnter)] (eid : EntityId)
    destroyEntity(eid)

[es(track=currentBulletId, REQUIRE=currentBulletId)]
def tutorial_tank_switch_bullet_type(evt : Event)
  query() <| $ [es(REQUIRE=tutor_stage__nextBulletType)] (eid : EntityId)
    destroyEntity(eid)

[es(REQUIRE=vehicle)]
def tutorial_tank_damage_tracks_es(evt : EventOnPartDamaged;
                                   dm_phys_parts__tracksPartIds : IntList;
                                   tutorial_target__targetId : string;
                                   tutorial_target__active : bool)
  if !tutorial_target__active
    return

  query() <| $ [es(REQUIRE=tutor_stage__damageTracks)] (eid : EntityId; tutor_stage__activateTarget : string)
    if tutor_stage__activateTarget == tutorial_target__targetId && has_value(dm_phys_parts__tracksPartIds, evt.partId)
      destroyEntity(eid)

[es(REQUIRE=vehicle)]
def tutorial_tank_damage_engine_es(evt : EventOnPartDamaged;
                                   dm_phys_parts__enginePartIds : IntList;
                                   tutorial_target__targetId : string;
                                   tutorial_target__active : bool)
  if !tutorial_target__active
    return

  query() <| $ [es(REQUIRE=tutor_stage__damageEngine)] (eid : EntityId; tutor_stage__activateTarget : string)
    if tutor_stage__activateTarget == tutorial_target__targetId && has_value(dm_phys_parts__enginePartIds, evt.partId)
      destroyEntity(eid)

[es(REQUIRE=vehicle)]
def tutorial_tank_damage_ammunition_es(evt : EventOnPartDamaged;
                                       dm_phys_parts__ammoPartIds : IntList;
                                       tutorial_target__targetId : string;
                                       tutorial_target__active : bool)
  if !tutorial_target__active
    return

  query() <| $ [es(REQUIRE=tutor_stage__damageAmmunition)] (eid : EntityId; tutor_stage__activateTarget : string)
    if tutor_stage__activateTarget == tutorial_target__targetId && has_value(dm_phys_parts__ammoPartIds, evt.partId)
      destroyEntity(eid)

[es(REQUIRE=heroVehicle)]
def tutorial_tank_damage_passenger_es(evt : EventOnEntityHit)
  if !has(evt.offender, "hero")
    return

  query() <| $ [es(REQUIRE=tutor_stage__damagePassanger)] (eid : EntityId; tutor_stage__activateTarget : string)
    query(evt.victim) <| $ [es] (human_anim__vehicleSelected : EntityId)
      query(human_anim__vehicleSelected) <| $ [es] (tutorial_target__targetId : string; tutorial_target__active : bool)
        if tutorial_target__active && tutor_stage__activateTarget == tutorial_target__targetId
          destroyEntity(eid)

[es(on_appear, REQUIRE=tutorial_tank__xrayId)]
def tutorial_tank_xray_hide_all_parts_es(evt : Event; var animchar_render : AnimcharRendComponent&)
  for i in range(animchar_render.sceneInstance.nodeCount)
    animchar_render.sceneInstance |> scene_instance_show_node(i, false)

[es(on_appear)]
def tutorial_tank_xray_show_part(evt : Event; tutor_action__tankXRayPartEnable : StringList; tutor_action__tankXRayId : string = "")
  query() <| $ [es] (var animchar_render : AnimcharRendComponent&; tutorial_tank__xrayId : string)
    for i in range(animchar_render.sceneInstance.nodeCount)
      animchar_render.sceneInstance |> scene_instance_show_node(i, false)

    if tutorial_tank__xrayId != tutor_action__tankXRayId
      return

    for nodeName in tutor_action__tankXRayPartEnable
      let nodeId = ronamemapex_get_name_id((*(*animchar_render.sceneInstance).lodsResource).names.node, string(nodeName))
      animchar_render.sceneInstance |> scene_instance_show_node(nodeId, true)

[es(REQUIRE=seat__isPlayer, track=seat__isPlayer)]
def tutorial_condition_switch_to_gunner_es(evt : Event; seat__isPlayer : bool)
  if seat__isPlayer
    query() <| $ [es(REQUIRE=tutor_condition__switchToGunner)] (eid : EntityId)
      destroyEntity(eid)

[es(track=gun__ammo_by_shell, REQUIRE=resolvedTurret)]
def tutor_condition_zero_ammo_es(evt : Event; gun__ammo_by_shell : IntList; gun__shellsAmmo : Array)
  query() <| $ [es(REQUIRE=tutor_condition__zeroAmmo)] (eid : EntityId)
    for i, curAmmo in iter_range(gun__ammo_by_shell), gun__ammo_by_shell
      let maxAmmo = gun__shellsAmmo[i] |> get_int() ?? 0
      if maxAmmo != 0 && curAmmo == 0
        destroyEntity(eid)
        return

[es(track=gun__ammo_by_shell, REQUIRE=resolvedTurret)]
def tutor_condition_resupply_ammo_es(evt : Event; gun__ammo_by_shell : IntList)
  query() <| $ [es(REQUIRE=tutor_condition__resupplyAmmo)] (eid : EntityId)
    for curAmmo in gun__ammo_by_shell
      if curAmmo != 0
        destroyEntity(eid)
        return

[es(tag=input, on_appear, on_event=EventDaInputInit, after=(vehicle_turret_input_appear, vehicle_turret_input_init_reset))]
def tutorial_tank_disable_shell_change(evt : Event; var vehicle_input__mainNextBulletType : int&)
  query() <| $ [es] (var tutor__saveNextBulletType : int&)
    tutor__saveNextBulletType = vehicle_input__mainNextBulletType
    vehicle_input__mainNextBulletType = -1

[es(tag=input, on_event=EventEntityDestroyed)]
def tutorial_tank_disable_shell_change_destroy(evt : Event; tutor__saveNextBulletType : int)
  query() <| $ [es] (var vehicle_input__mainNextBulletType : int&)
    vehicle_input__mainNextBulletType = tutor__saveNextBulletType

[es(on_appear)]
def tutorial_tank_disable_vehicle_seat_change_es(evt : Event;
                                                 eid : EntityId;
                                                 seat__id : int;
                                                 seat__vehicleEid : EntityId;
                                                 var seats_order__canPlaceManually : bool&)
  query(seat__vehicleEid) <| $ [es(REQUIRE=heroTutorialVehicle)] ([[shared_comp]] vehicle_seats__seats : Array)
    query() <| $ [es] (var tutor__saveVehicleSeats : BoolList&)
      let seatCount = length(vehicle_seats__seats)
      if length(tutor__saveVehicleSeats) != seatCount
        tutor__saveVehicleSeats |> resize(seatCount)

      tutor__saveVehicleSeats[seat__id] = seats_order__canPlaceManually
      seats_order__canPlaceManually = has(eid, "commanderSeat")

[es(on_event=EventEntityDestroyed)]
def tutorial_tank_enable_vehicle_seat_change_es(evt : Event; tutor__saveVehicleSeats : BoolList)
  query() <| $ [es(REQUIRE=heroTutorialVehicle)] (vehicle_seats__seatEids : EidList)
    for seat in vehicle_seats__seatEids
      query(seat) <| $ [es] (seat__id : int; seat__ownerEid : EntityId; var seats_order__canPlaceManually : bool&)
        seats_order__canPlaceManually = tutor__saveVehicleSeats[seat__id]
        query(seat__ownerEid) <| $ [es] (var squad_member__canBeLeader : bool&)
          squad_member__canBeLeader = true

def private any_crew_dead(seats)
  var found = false
  for seat in seats
    query(seat) <| $ [es] (seat__ownerEid : EntityId)
      query(seat__ownerEid) <| $ [es(REQUIRE=deadEntity)] ()
        found = true
    if found
      break
  return found

def private any_part_dead(parts, dm_state)
  for part in parts
    if int(get_rel_hp_fixed(dm_state, part)) <= 0
      return true
  return false

[es(REQUIRE=(vehicle, dm_events), after=damage_model_es, track=dm_events)]
def tutorial_tank_destroy_target_es(evt : Event;
                                    tutorial_target__targetId : string;
                                    tutorial_target__active : bool;
                                    vehicle_seats__seatEids : EidList;
                                    dm_phys_parts__enginePartIds : IntList;
                                    dm_phys_parts__ammoPartIds : IntList;
                                    damage_model : DamageModel)
  if !tutorial_target__active
    return

  find_query() <| $ [es] (eid : EntityId; tutor_stage__destroyTarget : string)
    if tutor_stage__destroyTarget != tutorial_target__targetId
      return false

    if !(any_crew_dead(vehicle_seats__seatEids) ||
         any_part_dead(dm_phys_parts__enginePartIds, damage_model.dmData) ||
         any_part_dead(dm_phys_parts__ammoPartIds, damage_model.dmData))
      return true

    destroyEntity(eid)
    return true

[es(on_appear)]
def tutor_tank_xray_init(evt : Event; tutor_tank__xrayTemplate : string; tutorial_target__targetId : string; transform : float3x4)
  createEntity(tutor_tank__xrayTemplate) <| $(var init)
    init |> set("tutorial_tank__xrayId", tutorial_target__targetId)
    init |> set("transform", transform)
