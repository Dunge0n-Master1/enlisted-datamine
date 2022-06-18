import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game object.
  One avatar\hero is controlled by one player, but player can have NO Avatars for example at all.
*/

///=========player scores=====
let state = {
  localPlayerKills = mkWatched(persist, "localPlayerKills", 0)
  localPlayerDeaths = mkWatched(persist, "localPlayerDeaths", 0)
  localPlayerHeadshots = mkWatched(persist, "localPlayerHeadshots", 0)
  localPlayerAwards = mkWatched(persist, "localPlayerAwards", [])
  localPlayerKillRating = mkWatched(persist, "localPlayerKillRating", 0.0)
  localPlayerKillRatingChange = mkWatched(persist,"localPlayerKillRatingChange", 0.0)
  localPlayerWinRating = mkWatched(persist, "localPlayerWinRating", 0.0)
  localPlayerWinRatingChange = mkWatched(persist, "localPlayerWinRatingChange", 0.0)
  localPlayersBattlesPlayed = mkWatched(persist, "localPlayersBattlesPlayed", -1)
  localPlayerNamePrefixIcon = mkWatched(persist, "localPlayerNamePrefixIcon", "")
}

let function trackScores(_eid,comp){
  if (comp["is_local"]) {
    state.localPlayerKills.update(comp["scoring_player__kills"])
    state.localPlayerDeaths.update(comp["scoring_player__deaths"])
    state.localPlayerHeadshots.update(comp["scoring_player__headshots"])
    state.localPlayersBattlesPlayed.update(comp["scoring_player__battlesPlayed"])

    state.localPlayerKillRating.update(comp["scoring_player__killRating"])
    state.localPlayerKillRatingChange.update(comp["scoring_player__killRatingChange"])
    state.localPlayerWinRating.update(comp["scoring_player__winRating"])
    state.localPlayerWinRatingChange.update(comp["scoring_player__winRatingChange"])
    state.localPlayerNamePrefixIcon(comp["namePrefixIcon"])
  }
}
ecs.register_es("local_player_scores_ui_es",
  { onChange = trackScores onInit = trackScores},
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["scoring_player__battlesPlayed", ecs.TYPE_INT, 0],
      ["scoring_player__kills", ecs.TYPE_INT, 0],
      ["scoring_player__deaths", ecs.TYPE_INT, 0],
      ["scoring_player__headshots", ecs.TYPE_INT, 0],
      ["scoring_player__killRating", ecs.TYPE_FLOAT, -1.0],
      ["scoring_player__killRatingChange", ecs.TYPE_FLOAT, 0.0],
      ["scoring_player__winRating", ecs.TYPE_FLOAT, -1.0],
      ["scoring_player__winRatingChange", ecs.TYPE_FLOAT, 0.0],
      ["namePrefixIcon", ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["player"],
  }
)

///=========player awards=====
  //awards are ECS ARRAY of something that looks like table but is not
  //you can't just work with array - it is PITA and probably not supportd

let function trackAwards(_eid,comp){
  if (comp.is_local) {
    state.localPlayerAwards.update(comp["awards"].getAll())
  }
}

ecs.register_es("local_player_awards_ui_es",
  { onChange = trackAwards onInit = trackAwards},
  {
    comps_track = [["is_local", ecs.TYPE_BOOL], ["awards", ecs.TYPE_ARRAY]],
    comps_rq = ["player"],
  }
)

return state
