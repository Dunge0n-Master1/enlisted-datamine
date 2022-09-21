module device_animation_common shared
require ecs
require DagorMath
require PhysVars
require game.es.device_state_common
require game.es.events
require AnimV20
require AnimatedPhys

def set_device_state(var phys_vars : PhysVars;
                     var device_anim__state : int&;
                     var device_anim__progress : float&;
                     device_anim__stateVarId : int;
                     device_anim__progressVarId : int;
                     device_anim__states : IntList;
                     state : DeviceAnimState;
                     progress : float)
  device_anim__state = int(state)
  device_anim__progress = progress
  if device_anim__stateVarId >= 0
    let stateEnum = device_anim__states[device_anim__state]
    setVar(phys_vars, device_anim__stateVarId, float(stateEnum))
  if device_anim__progressVarId >= 0
    setVar(phys_vars, device_anim__progressVarId, progress)

def set_backpack_state(var phys_vars : PhysVars;
                       var device_anim__state : int&;
                       var device_anim__progress : float&;
                       device_anim__stateVarId : int;
                       device_anim__progressVarId : int;
                       device_anim__states : IntList;
                       progress : float)
  set_device_state(phys_vars, device_anim__state, device_anim__progress, device_anim__stateVarId, device_anim__progressVarId, device_anim__states,
                   DeviceAnimState DEVICE_STATE_DISABLED, progress)

def post_state(atTime : float;
               device_animation__postTime : float;
               device_animation__endAt : float;
               var progress : float&;
               var state : DeviceAnimState&)
  let postEndTime = device_animation__endAt + device_animation__postTime
  progress = cvt(atTime, device_animation__endAt, postEndTime, 0.0, 1.0)
  state = DeviceAnimState DEVICE_STATE_POST
  return atTime <= postEndTime

def prepare_state(atTime : float;
                  loopStart : float;
                  device_animation__startAt : float;
                  var progress : float&;
                  var state : DeviceAnimState&)
  progress = cvt(atTime, device_animation__startAt, loopStart, 0.0, 1.0)
  state = DeviceAnimState DEVICE_STATE_PREPARE

def fire_state(atTime : float;
               dt : float;
               device_animation__firePrepareTime : float;
               device_animation__firePostTime : float;
               var device_animation__fireAt : float&;
               var progress : float&;
               var state : DeviceAnimState&)
  let firePrepareAt = device_animation__fireAt + device_animation__firePrepareTime
  let fireEndAt = firePrepareAt + device_animation__firePostTime
  state = DeviceAnimState DEVICE_STATE_FIRE
  if atTime < firePrepareAt
    progress = cvt(atTime, device_animation__fireAt, firePrepareAt, 0.0, 0.5)
    return false
  if atTime < fireEndAt
    progress = cvt(atTime, firePrepareAt, fireEndAt, 0.5, 1.0)
  else
    device_animation__fireAt = -1.0
  return atTime - dt <= firePrepareAt

def use_state(atTime : float;
              loopStart : float;
              device_animation__loopTime : float;
              var progress : float&;
              var state : DeviceAnimState&)
  let loop = (atTime - loopStart) / device_animation__loopTime
  progress = loop - floor(loop)
  state = DeviceAnimState DEVICE_STATE_USE
