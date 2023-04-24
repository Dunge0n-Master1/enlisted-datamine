require ecs
require app
require DagorMath
require DngHuman
require game.es.events
require math.base
require game.es.battle_area_common

struct LandPositionInfo
  pos : float2
  found : bool

def get_parachute_land_pos(playerTeam : int)
  var pos = float2(0.0)
  var pointsFound = 0
  ecs::query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, vehicleRespbase, playerRespawnBase, customRespawnBase))] (active : bool; transform : float3x4; team : int)
    if active && playerTeam == team
      pointsFound++
      pos += transform[3].xz
  if pointsFound > 0
    pos = pos / float(pointsFound)

  return [[LandPositionInfo pos = pos, found = pointsFound > 0]]


[es(after=human_parachute, REQUIRE=(hasParachute, parachuteDeployed))]
def human_parachute_wind(evt : CmdPostPhysUpdate;
                         transform : float3x4;
                         team : int;
                         human_parachute__eid : EntityId;
                         human_parachute_wind__speed : float;
                         human_parachute_wind__verticalSpeedThreshold : float;
                         human_parachute_wind__paratroopers : bool;
                         human_parachute_wind__landingPoint : float2;
                         human_parachute_wind__deadZone : float;
                         var human_net_phys : HumanActor;
                         var human_parachute_wind__isEnabled : bool&)
  if !human_parachute_wind__isEnabled
    return
  assume curVelocity = human_net_phys.phys.currentState.velocity
  if curVelocity.y > human_parachute_wind__verticalSpeedThreshold
    human_parachute_wind__isEnabled = false
    return
  query(human_parachute__eid) <| $ [es] (parachute__deployedAtTime : float;
                                         parachute__deployTime : float)
    var windTargetPos = float2()
    var findTarget = false
    if !human_parachute_wind__paratroopers
      let parachuteLandInfo = get_parachute_land_pos(team)
      if !parachuteLandInfo.found
        return
      windTargetPos = parachuteLandInfo.pos
      findTarget = true
    else
      windTargetPos = human_parachute_wind__landingPoint
      findTarget = true
    if length_sq(transform[3].xz - windTargetPos) < square(human_parachute_wind__deadZone) || !findTarget
      return
    let windSpeedScaled = cvt(get_sync_time(), parachute__deployedAtTime, parachute__deployedAtTime + parachute__deployTime,
                              0.0, human_parachute_wind__speed)
    let windVelocity = normalize(windTargetPos - transform[3].xz) * windSpeedScaled

    let afterWindHumanVelocity = float3(windVelocity.x, curVelocity.y, windVelocity.y)

    curVelocity = afterWindHumanVelocity
