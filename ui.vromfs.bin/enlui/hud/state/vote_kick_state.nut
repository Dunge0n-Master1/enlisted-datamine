import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerTeam, localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { VoteKickResult } = require("dasevents")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")

let voteToKickEnabled = Watched(false)
let voteToKickAccusedName = Watched(null)
let voteToKickYes = Watched([])
let voteToKickNo = Watched([])
let voteToKickAccused = Watched(ecs.INVALID_ENTITY_ID)
let lastKickedPlayerInfo = Watched({ name = null, kicked = false })

let getAccusedInfoQuery = ecs.SqQuery("getAccusedInfoQuery", {
  comps_ro = [
    ["name", ecs.TYPE_STRING],
    ["vote_to_kick__kicked", ecs.TYPE_BOOL],
    ["team", ecs.TYPE_INT],
  ]
})

ecs.register_es("vote_to_kick_ui_es",
  {
    onInit = @(...) voteToKickEnabled(true)
    onDestroy = @(...) voteToKickEnabled(false)
  },
  { comps_rq=["vote_to_kick__kickVotingTemplate"] },
  { tags="gameClient" }
)

ecs.register_es("vote_to_kick_process_ui_es",
  {
    [["onInit", "onChange"]] = function(_eid, comp) {
      let accused = comp["kick_voting__accused"]
      if (localPlayerEid.value == accused)
        return

      let voteYes = comp["kick_voting__voteYes"]
      let voteNo = comp["kick_voting__voteNo"]
      getAccusedInfoQuery(accused, function(_, comp) {
        if (comp["team"] != localPlayerTeam.value)
          return

        voteToKickAccusedName(remap_nick(comp["name"]))
        voteToKickYes(voteYes.getAll())
        voteToKickNo(voteNo.getAll())
        voteToKickAccused(accused)
      })
    },
    onDestroy = function(_eid, comp) {
      let accused = comp["kick_voting__accused"]
      getAccusedInfoQuery(accused, function(_, comp) {
        if (comp["team"] != localPlayerTeam.value)
          return

        voteToKickAccusedName(null)
        voteToKickYes([])
        voteToKickNo([])
        voteToKickAccused(ecs.INVALID_ENTITY_ID)
      })
    }
  },
  {
    comps_track = [
      ["kick_voting__voteYes", ecs.TYPE_EID_LIST],
      ["kick_voting__voteNo", ecs.TYPE_EID_LIST]
    ],
    comps_ro = [
      ["kick_voting__accused", ecs.TYPE_EID],
    ],
  },
  { tags="gameClient" }
)

ecs.register_es("vote_kick_notify_es",
  {
    [VoteKickResult] = function(evt, _eid, comp) {
        if (comp.team != localPlayerTeam.value || comp.is_local)
          return
        lastKickedPlayerInfo({
          name = remap_nick(comp.name)
          kicked = evt.kicked
        })
    },
  },
  {
    comps_ro = [
      ["name", ecs.TYPE_STRING],
      ["team", ecs.TYPE_INT],
      ["is_local", ecs.TYPE_BOOL],
    ],
  },
  {tags="gameClient"}
)

return {
  voteToKickEnabled
  voteToKickAccusedName
  voteToKickYes
  voteToKickNo
  voteToKickAccused
  lastKickedPlayerInfo
}