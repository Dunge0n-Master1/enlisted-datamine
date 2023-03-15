require ecs
require game.es.binocular_common
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require enlisted.events_enlisted
require HumanPhys
require AnimV20
require GeomNodeTree
require EnlistedHuman

[es(tag=server, on_appear, track=itemContainer)]
def binocular_track_inventory(evt : Event; eid : EntityId; itemContainer : EidList; var human_binocular__eid : EntityId&)
  human_binocular__eid = INVALID_ENTITY_ID
  for itemEid in itemContainer
    query(itemEid) <| $ [es(REQUIRE=binocular)] (var gun__owner : EntityId&)
      human_binocular__eid = itemEid
      gun__owner = eid

    if !!human_binocular__eid
      break


[es]
def binocular_on_switch_event(evt : CmdSwitchBinocular;
                              eid : EntityId;
                              isInVehicle : bool;
                              human_vehicle__canHoldWeapon : bool;
                              human_weap__gunEids : EidList;
                              human_binocular__eid : EntityId;
                              human_binocular__mode : bool;
                              human_binocular__prevGunInBinocSlotEid : EntityId;
                              var human_net_phys : HumanActor;
                              var human_binocular__prevGunSlot : int&;
                              var human_binocular__binocularSwitchRequested : bool&;
                              var human_binocular__binocularSwitchRequestedMode : bool&)
  if !human_binocular__eid || isInVehicle && !human_vehicle__canHoldWeapon
    return

  let binocularSlot = HUWeaponSlots EWS_PRIMARY

  human_binocular__binocularSwitchRequested = true
  human_binocular__binocularSwitchRequestedMode = !human_binocular__mode

  assume curWeapState = human_net_phys.phys.currentState.weapEquipState
  if curWeapState.curSlot == curWeapState.nextSlot
    reset_weapon_state(human_net_phys.phys)

  if human_binocular__mode
    if human_binocular__prevGunSlot != -1 && evt.choosePrevGunSlot == BinocularChooseWeapSlotMode ChoosePrevGunSlot
      set_chosen_weapon(human_net_phys.phys.producedCT, HUWeaponSlots(human_binocular__prevGunSlot))
    elif evt.choosePrevGunSlot == BinocularChooseWeapSlotMode ChooseFirstWeapWithAmmo
      using() <| $(var gunEids : EidList)
        gunEids := human_weap__gunEids
        gunEids[int(binocularSlot)] = human_binocular__prevGunInBinocSlotEid
        switch_to_first_weap_with_ammo(gunEids, human_net_phys.phys)
    human_binocular__prevGunSlot = -1
  else
    human_binocular__prevGunSlot = int(curWeapState.curSlot)
    set_chosen_weapon(human_net_phys.phys.producedCT, binocularSlot)

  sendEvent(eid, [[CmdInterruptReloadImmediately]])


def is_anim_progress_valid_to_change_weapon(human_net_phys : HumanActor)
  assume curWeapState = human_net_phys.phys.currentState.weapEquipState
  assume prevWeapState = human_net_phys.phys.previousState.weapEquipState
  if curWeapState.curSlot != HUWeaponSlots EWS_PRIMARY && curWeapState.nextSlot != HUWeaponSlots EWS_PRIMARY
    return false
  if curWeapState.progress < prevWeapState.progress && curWeapState.curState == HUWeaponEquipState EES_EQUIPING
    return true
  return false


def switch_binocular(eid : EntityId;
                     human_binocular__eid : EntityId;
                     var human_binocular__mode : bool&;
                     var human_binocular__prevGunInBinocSlotEid : EntityId&;
                     var human_weap__gunEids : EidList&)
  let targetSlot = int(HUWeaponSlots EWS_PRIMARY)

  if human_binocular__mode
    sendEventImmediate(human_weap__gunEids[targetSlot], [[CmdWeapAttach toEid=eid, isAttached=false, slotId=targetSlot]])
    human_binocular__mode = false
    human_weap__gunEids[targetSlot] = human_binocular__prevGunInBinocSlotEid
    human_binocular__prevGunInBinocSlotEid = INVALID_ENTITY_ID
  elif !human_binocular__mode
    sendEventImmediate(human_weap__gunEids[targetSlot], [[CmdWeapAttach toEid=eid, isAttached=false, slotId=targetSlot]])
    human_binocular__mode = true
    human_binocular__prevGunInBinocSlotEid = human_weap__gunEids[targetSlot]
    human_weap__gunEids[targetSlot] = human_binocular__eid


[es(no_order)]
def binocular_switch_update(info : ParallelUpdateFrameDelayed;
                            eid : EntityId;
                            human_net_phys : HumanActor;
                            human_binocular__eid : EntityId;
                            human_binocular__binocularSwitchRequested : bool&;
                            human_binocular__binocularSwitchRequestedMode : bool&;
                            var human_binocular__mode : bool&;
                            var human_binocular__prevGunInBinocSlotEid : EntityId&;
                            var human_weap__gunEids : EidList&)
  if !human_binocular__binocularSwitchRequested || human_binocular__mode == human_binocular__binocularSwitchRequestedMode
    return
  if !is_anim_progress_valid_to_change_weapon(human_net_phys)
    return
  switch_binocular(eid, human_binocular__eid, human_binocular__mode, human_binocular__prevGunInBinocSlotEid, human_weap__gunEids)


[es(track=human_weap__currentGunEid)]
def binocular_switch_request_close(evt : Event;
                                   human_weap__currentGunEid : EntityId;
                                   human_binocular__mode : bool;
                                   var human_binocular__binocularSwitchRequested : bool&;
                                   var human_binocular__binocularSwitchRequestedMode : bool&)
  if human_binocular__mode && has(human_weap__currentGunEid, "binocular")
    human_binocular__binocularSwitchRequested = false
  elif !human_binocular__mode && !has(human_weap__currentGunEid, "binocular")
    human_binocular__binocularSwitchRequested = false

  human_binocular__binocularSwitchRequestedMode = human_binocular__mode

[es(tag=gameClient, REQUIRE=hero, no_order)]
def binocular_switch_force_aim(info : ParallelUpdateFrameDelayed;
                               human_binocular__mode : bool;
                               human_net_phys : HumanActor;
                               var human_input__forceAim : bool&)
  if !human_binocular__mode || human_net_phys.phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_HOLSTERING
    human_input__forceAim = false


[es(tag=gameClient, track=human_binocular__mode)]
def binocular_enable_force_aim(evt : Event; human_binocular__mode : bool; var human_input__forceAim : bool&)
  if human_binocular__mode
    human_input__forceAim = true


[es(tag=gameClient)]
def binocular_disable_force_aim(evt : CmdSwitchBinocular; human_binocular__mode : bool; var human_input__forceAim : bool&)
  if human_binocular__mode
    human_input__forceAim = false


[es(tag=gameClient, REQUIRE=hero)]
def binocular_on_aiming(info : ParallelUpdateFrameDelayed;
                        eid : EntityId;
                        isAlive : bool;
                        human_net_phys__aimPosition : float;
                        human_binocular__aimPositionForCockpitShowing : float;
                        human_binocular__mode : bool;
                        human_binocular__cockpitEid : EntityId)
  if !isAlive
    return
  let isAiming = human_net_phys__aimPosition > human_binocular__aimPositionForCockpitShowing && human_binocular__mode
  if isAiming && !human_binocular__cockpitEid || !isAiming && !!human_binocular__cockpitEid
    sendEvent(eid, [[CmdSwitchBinocularCockpit enabled=isAiming]])


[es(tag=gameClient)]
def binocular_switch_cockpit(evt : CmdSwitchBinocularCockpit;
                             eid : EntityId;
                             human_binocular__eid : EntityId;
                             var human_binocular__cockpitEid : EntityId&)
  query(human_binocular__eid) <| $ [es] (var cockpit__isHeroInCockpit : bool&)
    if evt.enabled
      cockpit__isHeroInCockpit = true
      human_binocular__cockpitEid = createEntitySync("binocular_cockpit_base") <| $(var init : ComponentsInitializer)
        set(init, "cockpit__attachNodeIndex", -1)
        set(init, "cockpit__vehicleEid", eid)
        set(init, "cockpit__seatNo", -1)
        set(init, "cockpit__cameraTime", 1.f)
        set(init, "cockpit__zoomTime", 0.f)
        set(init, "cockpit__isAttached", true)
    else
      cockpit__isHeroInCockpit = false
      destroyEntity(human_binocular__cockpitEid)
      human_binocular__cockpitEid = INVALID_ENTITY_ID


[es(tag=gameClient, REQUIRE=hero, after=slot_attach_init_tms_es, before=vehicle_cockpit_update_animchar)]
def binocular_update_cockpit(info : ParallelUpdateFrameDelayed;
                             human_binocular__eid : EntityId;
                             human_binocular__cockpitEid : EntityId;
                             human_net_phys : HumanActor)
  query(human_binocular__cockpitEid) <| $ [es] (cockpit__offset : float3;
                                                cockpit__scale : float3;
                                                var transform : float3x4&)
    query(human_binocular__eid) <| $ [es] (animchar : AnimcharBaseComponent; gunmod__camNodeId : int)
      var baseTm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, gunmod__camNodeId, baseTm)

      transform[2] = human_net_phys.phys.producedCT.wishLookDir // forward
      transform[1] = baseTm[2] // up
      transform[0] = cross(transform[2], transform[1]) // side

      transform[0] *= cockpit__scale.x
      transform[1] *= cockpit__scale.y
      transform[2] *= cockpit__scale.z

      transform[3] = baseTm[3]
      transform[3] = transform * cockpit__offset


[es(tag=gameClient, track=(human_binocular__mode, human_binocular__cockpitEid, human_net_phys__curMoveState, human_net_phys__standState, possessedByPlr), REQUIRE=possessedByPlr)]
def binocular_update_visibility(evt : Event;
                                hero : Tag const?;
                                attaches_list : EidList;
                                human_net_phys__curMoveState : int;
                                human_net_phys__standState : int;
                                human_binocular__mode : bool;
                                human_binocular__eid : EntityId;
                                human_binocular__cockpitEid : EntityId;
                                var human__isHidingSlotsInScopeEnabled : bool&;
                                var human__visible : bool&)
  query(human_binocular__eid) <| $ [es] (var gun__visible : bool&)
    let isCrawlingMove = human_net_phys__standState == int(HUStandState ESS_CRAWL) && human_net_phys__curMoveState != int(HUMoveState EMS_STAND)

    gun__visible = human_binocular__mode && (!human_binocular__cockpitEid && !isCrawlingMove || hero == null && !isCrawlingMove)

  human__visible = !human_binocular__mode || !human_binocular__cockpitEid
  human__isHidingSlotsInScopeEnabled = !human_binocular__mode

  for attachEid in attaches_list
    query(attachEid) <| $ [es(REQUIRE=attachableBinoculars)] (var slot_attach__visible : bool&)
      slot_attach__visible = !human_binocular__mode


[es(tag=server, track=human_weap__currentGunEid, before=binocular_switch_request_close)]
def binocular_disable_on_switching_weap(evt : Event;
                                        eid : EntityId;
                                        human_weap__currentGunEid : EntityId;
                                        human_binocular__eid : EntityId;
                                        human_binocular__binocularSwitchRequested : bool;
                                        var human_binocular__mode : bool&;
                                        var human_binocular__prevGunInBinocSlotEid : EntityId&;
                                        var human_weap__gunEids : EidList&)
  if human_binocular__mode && !human_binocular__binocularSwitchRequested && !has(human_weap__currentGunEid, "binocular")
    switch_binocular(eid, human_binocular__eid, human_binocular__mode, human_binocular__prevGunInBinocSlotEid, human_weap__gunEids)


[es(tag=gameClient, track=possessedByPlr, REQUIRE_NOT=deadEntity)]
def binocular_disable_on_hero_change_client(evt : Event;
                                            eid : EntityId;
                                            possessedByPlr : EntityId)
  if !possessedByPlr
    sendEvent(eid, [[CmdSwitchBinocularCockpit enabled=false]])


[es(tag=server, track=possessedByPlr, REQUIRE_NOT=deadEntity)]
def binocular_disable_on_hero_change_server(evt : Event;
                                            eid : EntityId;
                                            possessedByPlr : EntityId;
                                            human_binocular__eid : EntityId;
                                            var human_binocular__mode : bool&;
                                            var human_binocular__prevGunInBinocSlotEid : EntityId&;
                                            var human_weap__gunEids : EidList&)
  if !possessedByPlr && human_binocular__mode
    switch_binocular(eid, human_binocular__eid, human_binocular__mode, human_binocular__prevGunInBinocSlotEid, human_weap__gunEids)


[es(tag=gameClient)]
def binocular_disable_on_die_client(evt : EventSoldierRecreateOnDie; eid : EntityId)
  sendEventImmediate(eid, [[CmdSwitchBinocularCockpit enabled=false]])


[es(tag=server, on_event=(EventSoldierRecreateOnDie, EventEntityDied), before=drop_held_weapon_on_death)]
def binocular_disable_on_die_server(evt : Event;
                                    eid : EntityId;
                                    human_binocular__eid : EntityId;
                                    var human_binocular__mode : bool&;
                                    var human_binocular__prevGunInBinocSlotEid : EntityId&;
                                    var human_weap__gunEids : EidList&)
  if human_binocular__mode
    switch_binocular(eid, human_binocular__eid, human_binocular__mode, human_binocular__prevGunInBinocSlotEid, human_weap__gunEids)


[es(on_event=EventEnterVehicle)]
def binocular_diable_on_enter_or_exit_vehicle(evt : Event;
                                              eid : EntityId;
                                              human_binocular__eid : EntityId;
                                              var human_net_phys : HumanActor;
                                              var human_binocular__prevGunSlot : int&;
                                              var human_binocular__mode : bool&;
                                              var human_binocular__prevGunInBinocSlotEid : EntityId&;
                                              var human_weap__gunEids : EidList&)
  if human_binocular__mode
    switch_binocular(eid, human_binocular__eid, human_binocular__mode, human_binocular__prevGunInBinocSlotEid, human_weap__gunEids)
    if human_binocular__prevGunSlot != -1
      set_chosen_weapon(human_net_phys.phys.producedCT, HUWeaponSlots(human_binocular__prevGunSlot))
    else
      switch_to_first_weap_with_ammo(human_weap__gunEids, human_net_phys.phys)
    human_binocular__prevGunSlot = -1

[es(tag=gameClient, track=(human_binocular__mode, human_binocular__cockpitEid))]
def binocular_switch_block_look_mode(evt : Event;
                                     human_binocular__mode : bool;
                                     human_binocular__cockpitEid : EntityId;
                                     var human_input__blockLookModeCounter : int&)
  if human_binocular__mode && !human_binocular__cockpitEid
    human_input__blockLookModeCounter++
  else
    human_input__blockLookModeCounter--
