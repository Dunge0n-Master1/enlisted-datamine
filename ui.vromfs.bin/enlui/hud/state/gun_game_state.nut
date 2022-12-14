import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let gunGameFriendlyTeamProgress = Watched(0)
let gunGameEnemyTeamProgress = Watched(0)

let gunGamePlayerProgress = Watched(0)
let gunGameLevelKillsDone = Watched(0)
let gunGameLevelKillsRequire = Watched(0)

let gunGameLevelCount =  Watched(0)

let gunGameLeaderPlayerEid = Watched(ecs.INVALID_ENTITY_ID)
let gunGameLeaderName = Watched("")
let gunGameLeaderTeam = Watched(0)

ecs.register_es("gun_game_levels_count_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    gunGameLevelCount(comp.gun_game__levelsCount)
  }
},
{ comps_track=[["gun_game__levelsCount", ecs.TYPE_INT]] })

ecs.register_es("gun_game_team_levels_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    if (localPlayerTeam.value == comp.team__id)
      gunGameFriendlyTeamProgress(comp.team__gunGameLevel)
    else
      gunGameEnemyTeamProgress(comp.team__gunGameLevel)
  }
},
{
  comps_track=[["team__gunGameLevel", ecs.TYPE_INT]],
  comps_ro=[["team__id", ecs.TYPE_INT]]
})

let getPlayerNameAndTeamQuery = ecs.SqQuery("getPlayerNameAndTeamQuery",
  { comps_ro = ["name", "team"] })

ecs.register_es("gun_game_leader_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    gunGameLeaderPlayerEid(comp.gun_game__leaderPlayerEid)
    getPlayerNameAndTeamQuery(comp.gun_game__leaderPlayerEid, function(_eid, comp) {
      gunGameLeaderTeam(comp.team)
      gunGameLeaderName(comp.name)
    })
  }
},
{
  comps_track=[["gun_game__leaderPlayerEid", ecs.TYPE_EID]]
})

ecs.register_es("gun_game_leader_name_and_team_track", {
  [["onInit","onChange"]] = function(eid, comp) {
    if (eid == gunGameLeaderPlayerEid.value) {
      gunGameLeaderTeam(comp.team)
      gunGameLeaderName(comp.name)
    }
  }
},
{
  comps_track=[["team", ecs.TYPE_INT], ["name", ecs.TYPE_STRING]]
})

ecs.register_es("gun_game_player_level_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    if (comp.is_local) {
      gunGamePlayerProgress(comp.gun_game__currentLevel)
      gunGameLevelKillsDone(comp.gun_game__killsForNextLevelRequire - comp.gun_game__killsForNextLevel)
      gunGameLevelKillsRequire(comp.gun_game__killsForNextLevelRequire)
    }
  }
},
{
  comps_track=[["gun_game__currentLevel", ecs.TYPE_INT],
               ["gun_game__killsForNextLevel", ecs.TYPE_INT],
               ["gun_game__killsForNextLevelRequire", ecs.TYPE_INT]],
  comps_ro=[["is_local", ecs.TYPE_BOOL]]
})

return {
  gunGameFriendlyTeamProgress
  gunGameEnemyTeamProgress
  gunGamePlayerProgress
  gunGameLevelKillsDone
  gunGameLevelKillsRequire
  gunGameLevelCount

  gunGameLeaderPlayerEid
  gunGameLeaderName
  gunGameLeaderTeam
}