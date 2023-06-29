require ecs
require math
require math.linear
require enlisted.events_enlisted
require game.utils.team

def update_look_at_zone_can_be_attacked_and_defended(zone_eid : EntityId;
                                                     team : int;
                                                     var can_be_attacked : bool&;
                                                     var can_be_defended : bool&)
  can_be_attacked = false
  can_be_defended = false
  query(zone_eid) <| $ [es] (capzone__owningTeam : int = -1;
                             capzone__mustBeCapturedByTeam : int = -1;
                             capzone__onlyTeamCanCapture : int = -1)
    can_be_attacked = (capzone__owningTeam != team &&
      (capzone__onlyTeamCanCapture == TEAM_UNASSIGNED && capzone__mustBeCapturedByTeam == TEAM_UNASSIGNED ||
      capzone__onlyTeamCanCapture == team ||
      capzone__mustBeCapturedByTeam == team))
    can_be_defended = !can_be_attacked

def calc_score(look_dot : float; dist_to_zone_sq : float; dist_to_ray : float)
  return (1.0 - look_dot) * (dist_to_zone_sq + dist_to_ray)

def calc_score_quickchat(look_dot : float; dist_to_zone_sq : float; dist_to_zone_sq_mult : float)
  return (1.0 - look_dot) + dist_to_zone_sq * dist_to_zone_sq_mult

def update_look_at_zone(aim_tm : float3x4;
                        min_dot : float;
                        min_dist_to_ray : float;
                        score_func : block<(look_dot : float; dist_to_zone : float; dist_to_ray : float) : float>;
                        var zone : EntityId&;
                        var zone_title : das_string&)
  let lookPos = aim_tm[3]
  let lookDir = aim_tm[0]
  var bestScore = FLT_MAX

  zone = INVALID_ENTITY_ID
  zone_title := ""
  query() <| $ [es(REQUIRE=capzone)] (eid : EntityId;
                                      active : bool;
                                      transform : float3x4;
                                      capzone__title : string = "")
    if !active
      return
    let dir = normalize(transform[3] - lookPos)
    let lookDot = dot(dir, lookDir)
    let distanceToRay = distance_to_line(transform[3], lookPos, lookDir)
    if lookDot < min_dot || distanceToRay > min_dist_to_ray
      return
    let distanceSqToZone = distance_sq(transform[3], lookPos)
    let score = invoke(score_func, lookDot, distanceSqToZone, distanceToRay)
    if score < bestScore
      bestScore = score
      zone = eid
      zone_title := capzone__title


[es(tag=gameClient, REQUIRE=human_input)]
def human_look_at_zone_es(act : ParallelUpdateFrameDelayed;
                          isAlive : bool;
                          human__aimTm : float3x4;
                          var human__lookAtZone : EntityId&;
                          var human__lookAtZoneTitle : das_string&;
                          human__lookAtZoneMinDot : float = 0.97;
                          human__lookAtZoneMinDistance : float = 5.0)
  if !isAlive
    return

  assume scoreFunc = $(look_dot : float; dist_to_zone : float; dist_to_ray : float) {
    return calc_score(look_dot, dist_to_zone, dist_to_ray); }
  update_look_at_zone(human__aimTm,
                      human__lookAtZoneMinDot,
                      human__lookAtZoneMinDistance,
                      scoreFunc,
                      human__lookAtZone,
                      human__lookAtZoneTitle)


[es(tag=gameClient, REQUIRE=human_input)]
def human_look_at_zone_quickchat_es(act : ParallelUpdateFrameDelayed;
                                    isAlive : bool;
                                    human__aimTm : float3x4;
                                    var human__lookAtZoneQuickchat : EntityId&;
                                    var human__lookAtZoneQuickchatTitle : das_string&;
                                    human__lookAtZoneQuickchatMinDot : float = 0.94;
                                    human__lookAtZoneQuickchatMinDistance : float = 40.0;
                                    human__lookAtZoneQuickchatDistanceSqMult : float = 1.e-7)
  if !isAlive
    return

  assume scoreFunc = $ [unused_argument(dist_to_ray)] (look_dot : float; dist_to_zone : float; dist_to_ray : float) {
    return calc_score_quickchat(look_dot, dist_to_zone, human__lookAtZoneQuickchatDistanceSqMult); }
  update_look_at_zone(human__aimTm,
                      human__lookAtZoneQuickchatMinDot,
                      human__lookAtZoneQuickchatMinDistance,
                      scoreFunc,
                      human__lookAtZoneQuickchat,
                      human__lookAtZoneQuickchatTitle)


[es(tag=gameClient, REQUIRE=human_input, after=human_look_at_zone_quickchat_es)]
def human_look_at_zone_quickchat_inside_es(act : ParallelUpdateFrameDelayed;
                                           isAlive : bool;
                                           capturer__capZonesIn : EidList;
                                           var human__lookAtZoneQuickchat : EntityId&;
                                           var human__lookAtZoneQuickchatTitle : das_string&)
  if !isAlive || empty(capturer__capZonesIn) || human__lookAtZoneQuickchat != INVALID_ENTITY_ID
    return

  for zone in capturer__capZonesIn
    query(zone) <| $ [es(REQUIRE=capzone)] (active : bool;
                                            capzone__title : string = "")
      if !active
        return
      human__lookAtZoneQuickchat = zone
      human__lookAtZoneQuickchatTitle := capzone__title

    if human__lookAtZoneQuickchat != INVALID_ENTITY_ID
      return


[es(tag=gameClient, REQUIRE=human_input, after=human_look_at_zone_quickchat_inside_es)]
def human_look_at_zone_quickchat_can_be_attacked_and_defended_es(act : ParallelUpdateFrameDelayed;
                                                                 team : int;
                                                                 human__lookAtZoneQuickchat : EntityId;
                                                                 var human__lookAtZoneQuickchatCanBeAttacked : bool&;
                                                                 var human__lookAtZoneQuickchatCanBeDefended : bool&)
  update_look_at_zone_can_be_attacked_and_defended(human__lookAtZoneQuickchat,
                                                   team,
                                                   human__lookAtZoneQuickchatCanBeAttacked,
                                                   human__lookAtZoneQuickchatCanBeDefended)
