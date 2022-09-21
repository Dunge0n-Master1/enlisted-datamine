require ecs
require DagorMath
require math.base
require soundEvent
require soundSystem
require enlisted.events_enlisted

def get_cart_pos(eid : EntityId; def_pos : float3)
  var pos = def_pos
  query(eid) <| $ [es] (transform : float3x4)
    pos = transform[3]
  return pos

def get_train_pos(train__cartEids : EidList)
  let listener = soundSystem::get_listener_pos()
  if length(train__cartEids) == 0
    return listener
  var prevPos = get_cart_pos(train__cartEids[0], listener)
  var pos = prevPos
  for idx in range(1, length(train__cartEids))
    let curPos = get_cart_pos(train__cartEids[idx], prevPos)
    var dir = prevPos - curPos
    let len = length(dir)
    dir = len > FLT_EPSILON ? dir / len : dir
    let p = curPos + dir * clamp(dot(listener - curPos, dir), 0., len)
    if length_sq(p - listener) < length_sq(pos - listener)
      pos = p
    prevPos = curPos
  return pos

[es(tag=sound, after=animchar_render_es)]
def train_sound_speed(info : ParallelUpdateFrameDelayed;
                      var train_sound_speed__inited : bool&;
                      var train_sound_speed__pos : float2&;
                      var train_sound_speed__speedSummarySq : float&;
                      var train_sound_speed__speedSamples : int&;
                      var train_sound_speed__prevNextSampleAt : float2&;
                      var train_sound_speed__speedAccel : float4&;
                      var train_sound_speed__speed : float&;
                      var train_sound_speed__accel : float&;
                      train_sound_speed__enabled : bool;
                      train__cartEids : EidList)

  if train_sound_speed__enabled && length(train__cartEids) > 0
    let pos = get_cart_pos(train__cartEids[0], soundSystem::get_listener_pos()).xz

    if !train_sound_speed__inited
      train_sound_speed__inited = true
      train_sound_speed__pos = pos

    train_sound_speed__speedSummarySq += safediv(length(train_sound_speed__pos - pos), info.dt)
    train_sound_speed__pos = pos
    ++train_sound_speed__speedSamples

    if info.curTime >= train_sound_speed__prevNextSampleAt.y
      train_sound_speed__prevNextSampleAt.x = train_sound_speed__prevNextSampleAt.y
      let SAMPLE_RATE = 1.
      train_sound_speed__prevNextSampleAt.y = info.curTime + SAMPLE_RATE
      train_sound_speed__speedAccel.z = train_sound_speed__speedAccel.x
      train_sound_speed__speedAccel.w = train_sound_speed__speedAccel.y
      let speed = safediv(train_sound_speed__speedSummarySq, float(train_sound_speed__speedSamples))
      train_sound_speed__speedSummarySq = 0.
      train_sound_speed__speedSamples = 0
      train_sound_speed__speedAccel.y = speed - train_sound_speed__speedAccel.x
      train_sound_speed__speedAccel.x = speed

    train_sound_speed__speed = cvt(info.curTime, train_sound_speed__prevNextSampleAt.x, train_sound_speed__prevNextSampleAt.y, train_sound_speed__speedAccel.z, train_sound_speed__speedAccel.x)
    train_sound_speed__accel = cvt(info.curTime, train_sound_speed__prevNextSampleAt.x, train_sound_speed__prevNextSampleAt.y, train_sound_speed__speedAccel.w, train_sound_speed__speedAccel.y)
  else // !train_sound_speed__enabled
    train_sound_speed__inited = false
    train_sound_speed__speed = 0.
    train_sound_speed__accel = 0.


[es(tag=sound, after=train_sound_speed)]
def train_sound(info : ParallelUpdateFrameDelayed;
                train_sound_speed__speed : float;
                train_sound_speed__accel : float;
                train_sound__path : string;
                train_sound__range : float;
                var train_sound__event : SoundEvent&;
                var train_sound_speed__enabled : bool&;
                train__cartEids : EidList)

  let listener = soundSystem::get_listener_pos()
  train_sound_speed__enabled = length(train__cartEids) > 0 && length_sq(get_cart_pos(train__cartEids[0], listener) - listener) < square(train_sound__range)
  let enable = train_sound_speed__enabled

  if train_sound__event.enabled != enable
    train_sound__event.enabled = enable
    if enable
      train_sound__event |> play(train_sound__path, get_train_pos(train__cartEids))
    else
      abandon(train_sound__event.handle)

  if train_sound__event.enabled
    set_var(train_sound__event.handle, "speed", train_sound_speed__speed)
    set_var(train_sound__event.handle, "acceleration", train_sound_speed__accel)
    set_pos(train_sound__event.handle, get_train_pos(train__cartEids))


[es(tag=sound, on_appear)]
def train_sound_on_appear(evt : Event;
                          var train_sound__range : float&;
                          train_sound__path : string)
  train_sound__range = get_max_distance(train_sound__path)
  if train_sound__range <= 0. || train_sound__range > 8000.
    sound_debug("train_sound__range={train_sound__range} is out of bounds")
    train_sound__range = 35.
