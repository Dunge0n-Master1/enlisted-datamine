import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game object.
  One avatar\hero is controlled by one player, but player can have NO Avatars for example at all.
*/

///=========player scores=====
let state = {
  localPlayersBattlesPlayed = mkWatched(persist, "localPlayersBattlesPlayed", -1)
  localPlayerNamePrefixIcon = mkWatched(persist, "localPlayerNamePrefixIcon", "")
}

let function trackScores(_eid,comp){
  if (comp["is_local"]) {
    state.localPlayersBattlesPlayed.update(comp["scoring_player__battlesPlayed"])
    state.localPlayerNamePrefixIcon(comp["namePrefixIcon"])
  }
}
ecs.register_es("local_player_scores_ui_es",
  { onChange = trackScores onInit = trackScores},
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["scoring_player__battlesPlayed", ecs.TYPE_INT, 0],
      ["namePrefixIcon", ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["player"],
  }
)

return state
