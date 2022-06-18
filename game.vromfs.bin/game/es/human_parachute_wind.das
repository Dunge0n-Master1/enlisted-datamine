require ecs
require app
require DagorMath
require EnlistedHuman
require game.es.events
require math.base


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
                         human_parachute_wind__deadZone : float;
                         var human_net_phys : HumanActor)
  query(human_parachute__eid) <| $ [es] (parachute__deployedAtTime : float;
                                         parachute__deployTime : float)
    let parachuteLandInfo = get_parachute_land_pos(team)
    if !parachuteLandInfo.found || length_sq(transform[3].xz - parachuteLandInfo.pos) < square(human_parachute_wind__deadZone)
      return

    let windSpeedScaled = cvt(get_sync_time(), parachute__deployedAtTime, parachute__deployedAtTime + parachute__deployTime,
                              0.0, human_parachute_wind__speed)
    let windVelocity = normalize(parachuteLandInfo.pos - transform[3].xz) * windSpeedScaled

    assume curVelocity = human_net_phys.phys.currentState.velocity
    let afterWindHumanVelocity = float3(windVelocity.x, curVelocity.y, windVelocity.y)

    curVelocity = afterWindHumanVelocity