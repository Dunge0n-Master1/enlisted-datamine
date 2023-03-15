require ecs
require app
require PhysVars
require EnlistedHumanAnim
require game.es.device_state_common
require EnlistedHuman
require HumanPhys
require AnimV20
require AnimatedPhys
require game.es.events
require game.es.device_animation_common
require enlisted.events_enlisted

[es(track=human_weap__currentGunSlot)]
def device_animation_check_unequipped(evt : Event; human_weap__currentGunSlot : int; human_net_phys : HumanActor; human_weap__gunEids : ecs::EidList)
  let curState = human_net_phys.phys.currentState.weapEquipState.curState
  if curState != HUWeaponEquipState EES_EQUIPED
    return
  let curSlot = human_weap__currentGunSlot
  for slot, weapEid in iter_range(human_weap__gunEids), human_weap__gunEids
    if slot == curSlot
      continue
    query(weapEid) <| $ [es] (var phys_vars : PhysVars;
                              var device_anim__state : int&;
                              var device_anim__progress : float&;
                              device_anim__stateVarId : int;
                              device_anim__progressVarId : int;
                              device_anim__states : ecs::IntList)
      set_backpack_state(phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, 0.0)

[es(no_order)]
def device_animation_equip(info : ParallelUpdateFrameDelayed;
                           eid : EntityId;
                           item__ownerEid : EntityId;
                           device_anim__stateVarId : int;
                           device_anim__progressVarId : int;
                           device_anim__states : ecs::IntList;
                           human_gun_attached : bool;
                           var phys_vars aka device__phys_vars : PhysVars;
                           var device_anim__state : int&;
                           var device_anim__progress : float&;
                           var animchar : AnimcharBaseComponent)
  query(item__ownerEid) <| $ [es] (human_weap__gunEids : ecs::EidList;
                                   human_anim : HumanAnimCtx;
                                   human_net_phys : HumanActor;
                                   phys_vars : PhysVars)
    let prevState = human_net_phys.phys.previousState.weapEquipState.curState
    let curState = human_net_phys.phys.currentState.weapEquipState.curState
    let curSlot = int(human_net_phys.phys.currentState.weapEquipState.curSlot)
    let nextSlot = int(human_net_phys.phys.currentState.weapEquipState.nextSlot)

    let progress = 1.0 - getVar(phys_vars, human_anim.changeWeaponVarId)

    if human_weap__gunEids[nextSlot] == eid
      if curState == HUWeaponEquipState EES_EQUIPING
        set_backpack_state(device__phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, progress)
    elif human_weap__gunEids[curSlot] == eid
      if curState == HUWeaponEquipState EES_HOLSTERING
        set_backpack_state(device__phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, progress)
      elif prevState == HUWeaponEquipState EES_HOLSTERING
        set_backpack_state(device__phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, 0.0)
      elif curState == HUWeaponEquipState EES_EQUIPED && prevState != HUWeaponEquipState EES_EQUIPED
        set_backpack_state(device__phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, 1.0)
      if !human_gun_attached
        animchar_act(animchar, 0.0, true)

[es(no_order)]
def device_animation(act : ParallelUpdateFrameDelayed;
                     eid : EntityId;
                     device_anim__stateVarId aka gun_device_anim__stateVarId : int;
                     device_anim__progressVarId aka gun_device_anim__progressVarId : int;
                     device_anim__states aka gun_device_anim__states : ecs::IntList;
                     device_animation__prepareTime : float;
                     device_animation__loopTime : float;
                     device_animation__firePrepareTime : float;
                     device_animation__firePostTime : float;
                     device_animation__postTime : float;
                     device_animation__startAt : float;
                     device_animation__endAt : float;
                     gun__owner : EntityId;
                     device_anim__isFpvVarId : int = -1;
                     var device_anim__state aka gun_device_anim__state : int&;
                     var device_anim__progress aka gun_device_anim__progress : float&;
                     var device_animation__fireAt : float&;
                     var device_animation__isActive : bool&;
                     var phys_vars aka gun_phys_vars : PhysVars)
  query(gun__owner) <| $ [es] (human_weap__gunEids : ecs::EidList;
                               human_weap__currentGunSlot : int;
                               human_net_phys : HumanActor;
                               device_anim__stateVarId : int;
                               device_anim__progressVarId aka human_device_anim__progressVarId : int;
                               device_anim__states aka human_device_anim__states : ecs::IntList;
                               isTpsView : bool = false;
                               watchedByPlr : EntityId = INVALID_ENTITY_ID;
                               var device_anim__state aka human_device_anim__state : int&;
                               var device_anim__progress aka human_device_anim__progress : float&;
                               var phys_vars : PhysVars)
    if human_weap__currentGunSlot < 0
      return

    if eid != human_weap__gunEids[human_weap__currentGunSlot]
      return

    let curState = human_net_phys.phys.currentState.weapEquipState.curState
    if curState != HUWeaponEquipState EES_EQUIPED
      return

    let atTime = get_sync_time()
    var progress = 1.0
    var state = DeviceAnimState DEVICE_STATE_DISABLED
    if device_animation__isActive
      let loopStart = device_animation__startAt + device_animation__prepareTime
      if device_animation__endAt > device_animation__startAt && atTime > device_animation__endAt
        device_animation__isActive = post_state(atTime, device_animation__postTime, device_animation__endAt, progress, state)
      elif atTime < loopStart
        prepare_state(atTime, loopStart, device_animation__startAt, progress, state)
      elif device_animation__fireAt > device_animation__startAt && atTime > device_animation__fireAt
        if fire_state(atTime, act.dt, device_animation__firePrepareTime, device_animation__firePostTime,
                      device_animation__fireAt, progress, state)
          sendEvent(eid, [[EventOnDeviceShoot]])
      else
        use_state(atTime, loopStart, device_animation__loopTime, progress, state)

    set_device_state(phys_vars, human_device_anim__state, human_device_anim__progress, device_anim__stateVarId,
                     human_device_anim__progressVarId, human_device_anim__states, state, progress)
    set_device_state(gun_phys_vars, gun_device_anim__state, gun_device_anim__progress, gun_device_anim__stateVarId,
                     gun_device_anim__progressVarId, gun_device_anim__states, state, progress)
    if device_anim__isFpvVarId >= 0
      let isViewedFromFPS = watchedByPlr != INVALID_ENTITY_ID && !isTpsView
      setVar(gun_phys_vars, device_anim__isFpvVarId, isViewedFromFPS ? 1.0 : 0.0)

[es(tag=gameClient, track=human_gun_attached)]
def device_anim_unequipped_animchar_update(evt : Event;
                                           device_anim__stateVarId : int;
                                           device_anim__progressVarId : int;
                                           device_anim__states : IntList;
                                           human_gun_attached : bool;
                                           var device_anim__state : int&;
                                           var device_anim__progress : float&;
                                           var phys_vars : PhysVars;
                                           var animchar : AnimcharBaseComponent;
                                           var anim_phys : AnimatedPhys;
                                           var device_animation__isActive : bool&)
  if !human_gun_attached
    set_backpack_state(phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, 0.0)
    device_animation__isActive = false;
    anim_phys_update(anim_phys, animchar, phys_vars);
    animchar_act(animchar, 0.01, true)
