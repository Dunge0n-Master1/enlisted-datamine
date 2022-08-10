require ecs
require math
require math.linear
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=human_input)]
def human_look_at_zone_es(act : ParallelUpdateFrameDelayed; isAlive : bool;
                          human__aimTm : float3x4; var human__lookAtZone : EntityId&;
                          human__lookAtZoneMinDot : float = 0.97; human__lookAtZoneMinDistance : float = 5.0)
  if !isAlive
    return
  let lookPos = human__aimTm[3]
  let lookDir = human__aimTm[0]
  var bestScore = 0.0
  var bestZone = INVALID_ENTITY_ID
  ecs::query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool; transform : float3x4)
    if !active
      return
    let dir = normalize(transform[3] - lookPos)
    let lookDot = dot(dir, lookDir)
    let distanceToRay = distance_to_line(transform[3], lookPos, lookDir)
    if lookDot < human__lookAtZoneMinDot || distanceToRay > human__lookAtZoneMinDistance
      return
    let ratio = (1.0 - lookDot) * distance_sq(transform[3], lookPos) + (1.0 - lookDot) * distanceToRay
    if ratio < bestScore || bestZone == INVALID_ENTITY_ID
      bestScore = ratio
      bestZone = eid
  human__lookAtZone = bestZone
