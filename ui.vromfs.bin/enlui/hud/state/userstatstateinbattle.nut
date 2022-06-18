import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { get_sync_time } = require("net")

let inGameUserstatState = mkWatched(persist, "inGameUserstatState", {})

let calcBattleTime = @(battle_time, started_at) {
  battle_time = (battle_time + started_at >= 0.0 ? get_sync_time() - started_at : 0.0).tointeger()
}

ecs.register_es("userstat_state_in_game_update_client_battletime_es", {
  function onUpdate(_, comp) {
    if (comp.is_local) {
      inGameUserstatState.mutate(@(v) v.__update(
        calcBattleTime(comp["scoring_player__battleTime"], comp["scoring_player__battleTimeLastStartedAt"])))
    }
  }
},
{
  comps_rq = ["player"]
  comps_ro = [
    ["is_local", ecs.TYPE_BOOL],
    ["scoring_player__battleTime", ecs.TYPE_FLOAT],
    ["scoring_player__battleTimeLastStartedAt", ecs.TYPE_FLOAT],
  ]
},
{tags = "gameClient", updateInterval = 60.0 /* 1 min */, after="*", before="*" }
)

ecs.register_es("track_userstat_state_in_game_es", {
  function onChange(_, comp) {
    if (comp.is_local) {
      inGameUserstatState(comp.userstatsInBattle.getAll().__merge(
        calcBattleTime(comp["scoring_player__battleTime"], comp["scoring_player__battleTimeLastStartedAt"])))
    }
  }
},
{
  comps_rq = ["player"]
  comps_ro = [
    ["is_local", ecs.TYPE_BOOL],
    ["scoring_player__battleTime", ecs.TYPE_FLOAT],
    ["scoring_player__battleTimeLastStartedAt", ecs.TYPE_FLOAT],
  ]
  comps_track = [["userstatsInBattle", ecs.TYPE_OBJECT]]
},
{tags = "gameClient"}
)

return inGameUserstatState