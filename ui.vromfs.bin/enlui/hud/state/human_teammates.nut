import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerTeam, localPlayerEid, localPlayerGroupId } = require("%ui/hud/state/local_player.nut")
let { INVALID_GROUP_ID } = require("matching.errors")
let { mkWatchedSetAndStorage, mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

//===============heroes stats===============
let heroesTrackComps = [
  ["team", ecs.TYPE_INT],
  ["possessedByPlr", ecs.TYPE_EID],
  ["human_anim__vehicleSelected", ecs.TYPE_EID],
  ["squad_member__squad", ecs.TYPE_EID],
  ["squad_member__playerEid", ecs.TYPE_EID],
  ["human_quickchat__requestAmmoBoxMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["human_quickchat__requestRallyPointMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["medic__healState", ecs.TYPE_INT],
]

let teammatePlayerInfoQuery = ecs.SqQuery("teammatePlayerInfoQuery", {
  comps_ro = [
    ["disconnected", ecs.TYPE_BOOL],
    ["groupId", ecs.TYPE_INT64, INVALID_GROUP_ID],
    ["player_group__memberIndex", ecs.TYPE_INT],
    ["name", ecs.TYPE_STRING],
    ["decorators__nickFrame", ecs.TYPE_STRING],
  ]
})

let {alivePossessedTeammates, alivePossessedTeammatesModify, alivePossessedTeammatesSetKeyVal, alivePossessedTeammatesDeleteKey} = mkFrameIncrementObservable({}, "alivePossessedTeammates")

let {
  teammatesAvatarsSet,
  teammatesAvatarsGetWatched,
  teammatesAvatarsUpdateEid,
  teammatesAvatarsDestroyEid
} = mkWatchedSetAndStorage("teammatesAvatars")

ecs.register_es("human_teammates_stats_ui_es",
  {
    [["onChange","onInit"]] = function(_evt, eid, comp){
      if (localPlayerTeam.value != comp["team"]){
        teammatesAvatarsDestroyEid(eid)
        alivePossessedTeammatesDeleteKey(eid)
        return
      }
      let res = {}
      foreach (i in heroesTrackComps)
        res[i[0]] <- comp[i[0]]
      res.isAlive <- comp.isAlive
      res.eid <- eid
      teammatePlayerInfoQuery(comp.possessedByPlr, @(_, playerComp) res.__update(playerComp))

      teammatesAvatarsUpdateEid(eid, res)
      if (comp.possessedByPlr == ecs.INVALID_ENTITY_ID || localPlayerEid.value == comp.squad_member__playerEid) {
        alivePossessedTeammatesDeleteKey(eid)
      }
      else {
        alivePossessedTeammatesSetKeyVal(eid, res)
      }
    },
    function onDestroy(_evt, eid, _comp){
      teammatesAvatarsDestroyEid(eid)
      alivePossessedTeammatesDeleteKey(eid)
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

ecs.register_es("human_teammates_players_ui_es",
  {
    [["onInit", "onChange"]] = function(_evt, _eid, comp){
      if (comp["is_local"] || comp["team"] != localPlayerTeam.value){
        return
      }
      let {possessed, name, groupId, disconnected, player_group__memberIndex} = comp
      alivePossessedTeammatesModify(function(value) {
        value?[possessed]?.__update({name, groupId, player_group__memberIndex, disconnected})
        return value
      })
    },
  },
  {
    comps_track = [
      ["team", ecs.TYPE_INT],
      ["is_local", ecs.TYPE_BOOL, false],
      ["disconnected", ecs.TYPE_BOOL],
      ["possessed", ecs.TYPE_EID],
      ["groupId", ecs.TYPE_INT64],
      ["player_group__memberIndex", ecs.TYPE_INT],
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING, null]
    ],
    comps_rq = ["player"]
  }
)

let teammatesAliveNum = Computed(@() alivePossessedTeammates.value.filter(@(teammate) !(teammate?.disconnected ?? true)).len())
let groupmatesAvatars = Computed(@() alivePossessedTeammates.value.filter(@(teammate)
  localPlayerGroupId.value != INVALID_GROUP_ID && (teammate?.groupId ?? INVALID_GROUP_ID) == localPlayerGroupId.value))

let groupmatesAvatarsStorage = {}
let groupmatesAvatarsGetWatched = @(eid) groupmatesAvatarsStorage?[eid]

let groupmatesAvatarsSet = Watched({})
let function updateGroupmatesAvatarsSetAndStorage(v){
  let s = v.map(function(_, eid) {
    if (eid not in groupmatesAvatarsStorage)
      groupmatesAvatarsStorage[eid] <- Computed(@() groupmatesAvatars.value?[eid]) //this looks awful but we need it
    return eid
  })
  let toDelete = []
  foreach (eid, _ in groupmatesAvatarsStorage){
    if (eid not in s)
      toDelete.append(eid)
  }
  foreach (eid in toDelete){
    delete groupmatesAvatarsStorage[eid]
  }
  groupmatesAvatarsSet(s)
}

updateGroupmatesAvatarsSetAndStorage(groupmatesAvatars.value)
groupmatesAvatars.subscribe(updateGroupmatesAvatarsSetAndStorage)

return {
  teammatesAvatarsSet
  teammatesAvatarsNotGroupmatesSet = Computed(function() {
    let groupmates = groupmatesAvatars.value
    return teammatesAvatarsSet.value.filter(@(_, eid) eid not in groupmates)
  })// alive soldier key eid, same team
  teammatesAvatarsGetWatched
  groupmatesAvatarsGetWatched
  groupmatesAvatarsSet
  teammatesAliveNum // num of alive soldiers, possessed, same team, not disconnected player, not local player
}
