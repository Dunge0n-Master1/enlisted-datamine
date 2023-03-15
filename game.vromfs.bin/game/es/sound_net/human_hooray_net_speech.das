require ecs
require app
require math
require math.base
require DagorRandom
require HumanPhys
require human_sounds_net.modules.human_sounds_net_events
require sound_utils_net.modules.sound_utils_net_events
require player

def is_facing_target(cur_pos : float3 const&; cur_dir : float3 const&; cur_team : int)
  var isTowardsAny : bool = false
  var isInsideAny : bool = false
  ecs::query() <| $ [es] (transform : float3x4; capzone__owningTeam : int; active : bool; sphere_zone__radius = 0.0)
    if (active && capzone__owningTeam != cur_team)
      let zonePos = transform[3]
      if distance_sq(zonePos, cur_pos) < square(sphere_zone__radius)
        isInsideAny = true
      elif dot(cur_dir, normalize(zonePos - cur_pos)) > 0.5
        isTowardsAny = true
  return isTowardsAny && !isInsideAny

def get_team_size(cur_eid : ecs::EntityId; cur_team : int; cur_pos : float3 const&)
  var teamSize : float = 0.0
  ecs::query() <| $ [es] (eid : ecs::EntityId;
                          team : int;
                          transform : float3x4;
                          human_hooray_speech__radius : float)
    if team == cur_team && eid != cur_eid
      if distance_sq(cur_pos, transform[3]) < human_hooray_speech__radius * human_hooray_speech__radius
        ++teamSize
  return teamSize

def check_artillery_warning(human_pos : float3 const&)
  return ecs::find_query() <| $ [es] (artillery__targetPos : float3&; artillery__dispersion : float)
    return length_sq(human_pos - artillery__targetPos) < square(artillery__dispersion)

def request_speech(eid : EntityId; pos : float3 const&)
  if !check_artillery_warning(pos)
    sendEvent(eid, [[CmdRequestHumanSpeech phrase="hooray"]])


def start_hooray(eid : ecs::EntityId; transform : float3x4; team : int; var human_hooray_speech__morale : float&; var human_hooray_speech__sensitivity : float&)
  request_speech(eid, transform[3])
  let curTeam = team
  let curPos = transform[3]
  let curMorale = human_hooray_speech__morale
  ecs::query() <| $ [es] (team : int;
                          transform : float3x4;
                          var human_hooray_speech__morale : float&;
                          var human_hooray_speech__delay : float&;
                          human_hooray_speech__delayMinMax : float2;
                          human_hooray_speech__sensitivity : float;
                          human_hooray_speech__radius : float)
    if team == curTeam
      if distance_sq(curPos, transform[3]) < human_hooray_speech__radius * human_hooray_speech__radius
        human_hooray_speech__morale += curMorale * human_hooray_speech__sensitivity
        if human_hooray_speech__delay < 0.
          human_hooray_speech__delay = rnd_float(human_hooray_speech__delayMinMax.x, human_hooray_speech__delayMinMax.y)
  human_hooray_speech__morale = 0.
  human_hooray_speech__sensitivity = 0.


[es(tag=server, no_order)]
def human_hooray_net_speech_update(info : ParallelUpdateFrameDelayed;
                                   eid : EntityId;
                                   human_net_phys__curMoveState : int;
                                   human_hooray_speech__chance : int;
                                   var human_hooray_speech__lookup : float&;
                                   var human_hooray_speech__sensitivity : float&;
                                   human_hooray_speech__restore : float;
                                   var human_hooray_speech__morale : float&;
                                   human_hooray_speech__decay : float;
                                   human_hooray_speech__threshold : float;
                                   var human_hooray_speech__delay : float&;
                                   var human_hooray_speech__timer : float&;
                                   transform : float3x4;
                                   team : int)
  human_hooray_speech__timer = max(0.0, human_hooray_speech__timer - info.dt)
  if human_hooray_speech__delay > 0.0
    human_hooray_speech__delay -= info.dt
    return

  if human_hooray_speech__morale >= human_hooray_speech__threshold
    if human_hooray_speech__chance >= rnd_int(0, 100)
      start_hooray(eid, transform, team, human_hooray_speech__morale, human_hooray_speech__sensitivity)
    human_hooray_speech__morale = 0.0
    human_hooray_speech__sensitivity = 0.0

  if human_net_phys__curMoveState == int(HUMoveState EMS_SPRINT) && human_hooray_speech__timer > 0.0
    human_hooray_speech__lookup += info.dt
    if human_hooray_speech__lookup >= 1.0
      human_hooray_speech__lookup = 0.0
      if is_facing_target(transform[3], transform[0], team)
        human_hooray_speech__morale += min(get_team_size(eid, team, transform[3]), 3.0) * human_hooray_speech__sensitivity
  else
    human_hooray_speech__morale = max(0.0, human_hooray_speech__morale - info.dt * human_hooray_speech__decay)
  human_hooray_speech__sensitivity = min(human_hooray_speech__sensitivity + info.dt * human_hooray_speech__restore, 1.0)

[es(tag=server, on_event=CmdHumanHoorayRequest)]
def human_hooray_net_speech_request(evt : Event; eid : ecs::EntityId;
                                    var human_hooray_speech__sensitivity : float&;
                                    var human_hooray_speech__morale : float&;
                                    human_hooray_speech__threshold : float;
                                    var human_hooray_speech__lastRequestTime : float&;
                                    transform : float3x4;
                                    team : int)
  if human_hooray_speech__lastRequestTime < 0. || get_sync_time() > human_hooray_speech__lastRequestTime + 5.
    human_hooray_speech__lastRequestTime = get_sync_time()
    human_hooray_speech__morale += human_hooray_speech__threshold
    start_hooray(eid, transform, team, human_hooray_speech__morale, human_hooray_speech__sensitivity)
