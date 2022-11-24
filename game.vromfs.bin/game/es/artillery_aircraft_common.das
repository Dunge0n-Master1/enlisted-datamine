require ecs
require app
require math.base
require game.utils.team
require DagorSystem

module artillery_aircraft_common shared

def calc_aircraft_request_dir(ownerTeam : int)
  var countFriendlyTeam = 0
  var spawnFriendlyTeam = float3()

  var countEnemyTeam = 0
  var spawnEnemyTeam = float3()

  query() <| $ [es(REQUIRE=aircraftRespbase)] (team : int;
                                               transform : float3x4)
    if team == TEAM_UNASSIGNED
      return

    if ownerTeam == team
      countFriendlyTeam = countFriendlyTeam + 1
      spawnFriendlyTeam += transform[3]
    else
      countEnemyTeam = countEnemyTeam + 1
      spawnEnemyTeam += transform[3]
      return

  var dir = float2(1., 0.)

  if countEnemyTeam == 0 || countFriendlyTeam == 0
    logerr("Need at least one friendly / enemy aircraft spawn point")
  else
    dir = normalize((spawnEnemyTeam / float(countEnemyTeam)).xz - (spawnFriendlyTeam / float(countFriendlyTeam)).xz)

  return dir