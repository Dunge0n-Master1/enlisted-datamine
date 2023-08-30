require ecs
require sound_utils.modules.sound_player_common
require DagorMath
require Dacoll
require soundEvent
require enlisted.events_enlisted
require mech


let ON_GROUND = 2
let IN_AIR = 1
let UNINITED = 0


[es(tag=sound)]
def mech_steps_sound_fx(evt : EventMechStepSound;
                        sound_control__shouldPlay : bool;
                        is_watched_sound : bool;
                        mech_steps_sound__minMaxSpeed : float2;
                        [[shared_comp]] mech_steps_sound__stepPath : Object;
                        sound_tags : Object;
                        walker_net_phys : WalkerPhysActor)

  if !sound_control__shouldPlay
    return

  let pos = evt.pos
  var handle = sound_player_common::play_path(mech_steps_sound__stepPath, sound_tags, is_watched_sound, pos, false)
  set_var(handle, "force", cvt(length(walker_net_phys.phys.currentState.velocity), mech_steps_sound__minMaxSpeed.x, mech_steps_sound__minMaxSpeed.y, 0., 1.))
  var water = 0.
  if traceht_water(pos, water)
    water = max(0., water - pos.y)
    if water > 0.
      set_var(handle, "depth", water)
  abandon(handle)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def mech_steps_sound_update(evt : Event;
                            sound_control__shouldPlay : bool;
                            is_watched_sound : bool;
                            mech_steps_sound__minMaxSpeed : float2;
                            var mech_steps_sound__feetIdx : int&;
                            var mech_steps_sound__onGroundState : IntList&;
                            var mech_steps_sound__servoEvent : SoundEvent&;
                            [[shared_comp]] mech_steps_sound__stepPath : Object;
                            [[shared_comp]] mech_steps_sound__servoPath : Object;
                            sound_tags : Object;
                            transform : float3x4;
                            walker_net_phys : WalkerPhysActor)

  let numLimbs = length(walker_net_phys.phys.currentState.limbs)
  if !sound_control__shouldPlay || numLimbs == 0 || length(mech_steps_sound__onGroundState) != numLimbs
    return

  let idx = mech_steps_sound__feetIdx
  mech_steps_sound__feetIdx = (++mech_steps_sound__feetIdx) % min(length(walker_net_phys.phys.currentState.limbs), 4)

  let wasInited = mech_steps_sound__onGroundState[idx] != UNINITED
  let prevOnGround = mech_steps_sound__onGroundState[idx] == ON_GROUND
  let isOnGround = walkerPhys_isOnGround(walker_net_phys.phys, idx)
  if wasInited || isOnGround
    mech_steps_sound__onGroundState[idx] = isOnGround ? ON_GROUND : IN_AIR

  if isOnGround && !prevOnGround && wasInited
    var handle = sound_player_common::play_path(mech_steps_sound__stepPath, sound_tags, is_watched_sound, transform[3], false)
    set_var(handle, "force", cvt(length(walker_net_phys.phys.currentState.velocity), mech_steps_sound__minMaxSpeed.x, mech_steps_sound__minMaxSpeed.y, 0., 1.))
    var water = 0.
    if traceht_water(transform[3], water)
      water = max(0., water - transform[3].y)
      if water > 0.
        set_var(handle, "depth", water)
    abandon(handle)

  // servo
  if !isOnGround && prevOnGround && wasInited
    let speed = length(walker_net_phys.phys.currentState.velocity)
    abandon(mech_steps_sound__servoEvent.handle)
    mech_steps_sound__servoEvent.handle = sound_player_common::play_path(mech_steps_sound__servoPath, sound_tags, is_watched_sound, transform[3], false)
    set_var(mech_steps_sound__servoEvent.handle, "speed", speed)
    mech_steps_sound__servoEvent.enabled = true

  if mech_steps_sound__servoEvent.enabled
    if is_playing(mech_steps_sound__servoEvent.handle)
      set_pos(mech_steps_sound__servoEvent.handle, transform[3])
    else
      release(mech_steps_sound__servoEvent.handle)
      mech_steps_sound__servoEvent.enabled = false


[es(tag=sound, on_appear, track=sound_control__shouldPlay, REQUIRE=sound_control__shouldPlay)]
def mech_steps_sound_toggle(evt : Event;
                            var mech_steps_sound__feetIdx : int&;
                            var mech_steps_sound__onGroundState : IntList&;
                            walker_net_phys : WalkerPhysActor)
  mech_steps_sound__feetIdx = 0
  let numLimbs = length(walker_net_phys.phys.currentState.limbs)
  resize(mech_steps_sound__onGroundState, numLimbs)
  for i in iter_range(mech_steps_sound__onGroundState)
    mech_steps_sound__onGroundState[i] = UNINITED
