require ecs
require math.base
require DagorMath
require DagorMathUtils

let MAX_TEAM_COUNT = 2u

struct MissionTeamCenterInfo
  middle : float3
  dir : float3
  pointCount : int

struct MissionCenterInfo
  middle : float3
  teams : MissionTeamCenterInfo[MAX_TEAM_COUNT]

def private find_mission_center_point()
  var pointsCount = 0
  var info = [[MissionCenterInfo]]
  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, playerRespawnBase, customRespawnBase))] (transform : float3x4; team : int)
    let teamIdx = team - 1
    if uint(teamIdx) >= MAX_TEAM_COUNT
      return

    ++pointsCount
    info.teams[teamIdx].pointCount++
    info.teams[teamIdx].middle += transform[3]
    info.middle += transform[3]

  if pointsCount > 0
    info.middle = info.middle / float(pointsCount)

  for team in info.teams
    if team.pointCount > 0
      team.middle = team.middle / float(team.pointCount)
    team.dir = normalize(team.middle - info.middle)

  return info

def create_spawn(middle, additional_pos, team_id, resp_type, max_vehicle_on_spawn, resp_time, templ)
  createEntity(templ) <| $(init)
    var tm : float3x4
    tm |> identity()
    tm[3] = middle + additional_pos

    var pos = middle
    pos[1] = tm[3][1]

    var rotTm : float3x4
    let dir = normalize(pos - tm[3])
    make_tm(dir_to_quat(dir), rotTm)

    init |> set("transform", tm * rotTm)
    init |> set("team", team_id)
    init |> set("respawnbaseType", resp_type)
    init |> set("maxVehicleOnSpawn", max_vehicle_on_spawn)
    init |> set("respTime", resp_time)

[es(tag=server, on_event=EventLevelLoaded)]
def aircraft_respawn_creator_init_es(evt : Event;
                                     var respawn_creator__middlePos : float3&;
                                     respawn_creator__dirMult : float;
                                     respawn_creator__additionalHeight : float;
                                     airResupplyTemplate : string;
                                     respawnTemplate : string;
                                     respawn_creator__airRespTypeFighter : string;
                                     respawn_creator__airRespTypeAssault : string;
                                     maxVehicleOnSpawn : int = 1;
                                     respTime : int = 120;
                                     respawn_creator__airRespAdditionalHeight : float = 200f;
                                     respawn_creator__airRespAdditionalAngle : float = 15f;
                                     respawn_creator__resupplyZoneAngle : float = 60f)
  let info = find_mission_center_point()
  respawn_creator__middlePos = info.middle

  for idx, team in iter_range(info.teams), info.teams
    let rotateAngle = angles_to_dir(float2(dir_to_angles(team.dir).x + deg_to_rad(respawn_creator__resupplyZoneAngle), 0.))
    let middlePos = info.middle + float3(0f, respawn_creator__additionalHeight, 0f)
    let teamId = idx + 1
    createEntity(airResupplyTemplate) <| $(init)
      var tm : float3x4
      tm |> identity()
      tm[3] = middlePos + respawn_creator__dirMult * rotateAngle
      init |> set("transform", tm)
      init |> set("resupply_zone__team", teamId)

    var additionalPos = angles_to_dir(float2(dir_to_angles(team.dir).x + deg_to_rad(respawn_creator__airRespAdditionalAngle), 0.)) * respawn_creator__dirMult
    create_spawn(middlePos, additionalPos, teamId, respawn_creator__airRespTypeFighter, maxVehicleOnSpawn, respTime, respawnTemplate)

    additionalPos[1] += respawn_creator__airRespAdditionalHeight
    create_spawn(middlePos, additionalPos, teamId, respawn_creator__airRespTypeAssault, maxVehicleOnSpawn, respTime, respawnTemplate)

    additionalPos = angles_to_dir(float2(dir_to_angles(team.dir).x + deg_to_rad(-respawn_creator__airRespAdditionalAngle), 0.)) * respawn_creator__dirMult
    create_spawn(middlePos, additionalPos, teamId, respawn_creator__airRespTypeFighter, maxVehicleOnSpawn, respTime, respawnTemplate)

    additionalPos[1] += respawn_creator__airRespAdditionalHeight
    create_spawn(middlePos, additionalPos, teamId, respawn_creator__airRespTypeAssault, maxVehicleOnSpawn, respTime, respawnTemplate)
