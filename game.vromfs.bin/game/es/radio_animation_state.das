require ecs
require app
require PhysVars
require game.es.device_state_common
require AnimV20
require AnimatedPhys
require game.es.device_animation_common
require enlisted.events_enlisted

[es(tag=gameClient)]
def radio_animation(act : ParallelUpdateFrameDelayed;
                    device_anim__stateVarId aka human_device_anim__stateVarId : int;
                    device_anim__progressVarId aka human_device_anim__progressVarId : int;
                    device_anim__states aka human_device_anim__states : IntList;
                    human_weap__radioEid : EntityId;
                    isTpsView : bool = false;
                    watchedByPlr : EntityId = INVALID_ENTITY_ID;
                    human_weap__radioMode : bool;
                    var device_anim__state aka human_device_anim__state : int&;
                    var device_anim__progress aka human_device_anim__progress : float&;
                    var phys_vars aka human_phys_vars : PhysVars)
  if !human_weap__radioMode
    return

  query(human_weap__radioEid) <| $ [es] (device_anim__stateVarId : int;
                                         device_anim__progressVarId : int;
                                         device_anim__states : IntList;
                                         device_animation__prepareTime : float;
                                         device_animation__loopTime : float;
                                         device_animation__postTime : float;
                                         device_animation__startAt : float;
                                         device_animation__endAt : float;
                                         device_anim__isFpvVarId : int = -1;
                                         var device_anim__state : int&;
                                         var device_anim__progress : float&;
                                         var phys_vars : PhysVars)
    let atTime = get_sync_time()
    var progress = 1.0
    var state = DeviceAnimState DEVICE_STATE_DISABLED
    let loopStart = device_animation__startAt + device_animation__prepareTime
    if device_animation__endAt > device_animation__startAt && atTime > device_animation__endAt
      post_state(atTime, device_animation__postTime, device_animation__endAt, progress, state)
    elif atTime < loopStart
      prepare_state(atTime, loopStart, device_animation__startAt, progress, state)
    else
      use_state(atTime, loopStart, device_animation__loopTime, progress, state)

    set_device_state(human_phys_vars, human_device_anim__state, human_device_anim__progress, human_device_anim__stateVarId,
                     human_device_anim__progressVarId, human_device_anim__states, state, progress)
    set_device_state(phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, state, progress)
    if device_anim__isFpvVarId >= 0
      let isViewedFromFPS = watchedByPlr != INVALID_ENTITY_ID && !isTpsView
      setVar(phys_vars, device_anim__isFpvVarId, isViewedFromFPS ? 1.0 : 0.0)


[es(tag=gameClient, track=human_weap__radioMode)]
def radio_anim_unequipped(evt : Event; human_weap__radioMode : bool; human_weap__radioEid : EntityId)
  if human_weap__radioMode
    return
  query(human_weap__radioEid) <| $ [es] (device_anim__stateVarId : int;
                                         device_anim__progressVarId : int;
                                         device_anim__states : IntList;
                                         var device_anim__state : int&;
                                         var device_anim__progress : float&;
                                         var phys_vars : PhysVars;
                                         var animchar : AnimcharBaseComponent;
                                         var anim_phys : AnimatedPhys)
    set_backpack_state(phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states, 0.0)
    anim_phys_update(anim_phys, animchar, phys_vars)
    animchar_act(animchar, 0.01, true)
