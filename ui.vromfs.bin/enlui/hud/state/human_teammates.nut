import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerTeam, localPlayerGroupId } = require("%ui/hud/state/local_player.nut")
let { INVALID_GROUP_ID } = require("matching.errors")


//===============heroes stats===============
let heroesTrackComps = [
  ["team", ecs.TYPE_INT],
  ["possessedByPlr", ecs.TYPE_EID],
  ["human_anim__vehicleSelected", ecs.TYPE_EID],
  ["squad_member__squad", ecs.TYPE_EID],
  ["human_quickchat__requestAmmoBoxMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["human_quickchat__requestRallyPointMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["medic__healState", ecs.TYPE_INT],
]

let teammatePlayerInfoQuery = ecs.SqQuery("teammatePlayerInfoQuery", {
  comps_ro = [
    ["disconnected", ecs.TYPE_BOOL],
    ["groupId", ecs.TYPE_INT64, INVALID_GROUP_ID],
    ["name", ecs.TYPE_STRING],
    ["decorators__nickFrame", ecs.TYPE_STRING],
  ]
})

let alivePossessedTeammates = Watched({})
let teammatesAvatars = Watched({})

let function deleteEid(eid, state){
  if (eid in state.value)
    state.mutate(@(v) delete v[eid])
}

ecs.register_es("human_teammates_stats_ui_es",
  {
    [["onChange","onInit"]] = function(_evt, eid, comp){
      if (localPlayerTeam.value != comp["team"]){
        deleteEid(eid, teammatesAvatars)
        deleteEid(eid, alivePossessedTeammates)
        return
      }
      let res = {}
      foreach (i in heroesTrackComps)
        res[i[0]] <- comp[i[0]]
      res.isAlive <- comp.isAlive
      teammatePlayerInfoQuery(comp.possessedByPlr, @(_, playerComp) res.__update(playerComp))

      teammatesAvatars.mutate(@(value) value[eid] <- res)
      if (comp.possessedByPlr == INVALID_ENTITY_ID)
        deleteEid(eid, alivePossessedTeammates)
      else
        alivePossessedTeammates.mutate(@(value) value[eid] <- res)
    },
    function onDestroy(_evt, eid, _comp){
      deleteEid(eid, teammatesAvatars)
      deleteEid(eid, alivePossessedTeammates)
    }
  },
  {
    comps_ro = [
      ["isAlive", ecs.TYPE_BOOL ],
    ]
    comps_rq = ["human"]
    comps_no = ["watchedByPlr", "deadEntity"]
    comps_track = heroesTrackComps
  }
)

//===============player teammates stats===============

let players = mkWatched(persist, "players", {})

let playerCompsTrack = [
  ["team", ecs.TYPE_INT],
  ["is_local", ecs.TYPE_BOOL, false],
  ["disconnected", ecs.TYPE_BOOL],
  ["possessed", ecs.TYPE_EID],
  ["groupId", ecs.TYPE_INT64],
  ["name", ecs.TYPE_STRING]
]

ecs.register_es("human_teammates_players_ui_es",
  {
    [["onInit", "onChange"]] = function(_evt, eid, comp){
      if (comp["is_local"] || comp["team"] != localPlayerTeam.value){
        deleteEid(eid, players)
        return
      }
      let res = {}
      foreach (i in playerCompsTrack){
        let compName = i[0]
        res[compName] <- comp[compName]
      }
      players.mutate(@(value) value[eid] <- res)
      alivePossessedTeammates.mutate(@(value) value?[comp.possessed]?.__update({
        name = comp.name,
        groupId = comp.groupId,
        disconnected = comp.disconnected
      }))
    },
    function onDestroy(_evt, eid, _comp){
      deleteEid(eid, players)
    }
  },
  {comps_track = playerCompsTrack, comps_rq = ["player"]}
)

let teammatesConnectedNum = Computed(@() players.value.filter(@(player) !player.disconnected).len())
let teammatesAliveNum = Computed(@() alivePossessedTeammates.value.filter(@(teammate) !(teammate?.disconnected ?? true)).len())
let groupmatesAvatars = Computed(@() alivePossessedTeammates.value.filter(@(teammate)
  localPlayerGroupId.value != INVALID_GROUP_ID && (teammate?.groupId ?? INVALID_GROUP_ID) == localPlayerGroupId.value))

return {
  teammatesAvatars // alive soldier, not watched, same team
  groupmatesAvatars // alive soldier, possessed, not watched, same team, same group
  teammatesAliveNum // num of alive soldiers, possessed, same team, not disconnected player, not local player
  teammatesConnectedNum // num of players, same team, not disconnected, not local
}
