import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game object.
  One avatar\hero is controlled by one player, but player can have NO Avatars for example at all.
*/

///=========player scores=====
let localPlayerNamePrefixIcon = Watched("")

ecs.register_es("local_player_scores_ui_es",
  { [["onChange", "onInit"]] = function(_, __, comp){
    if (comp["is_local"]) {
      localPlayerNamePrefixIcon(comp["namePrefixIcon"])
    }
  }
},
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["namePrefixIcon", ecs.TYPE_STRING, ""],
    ],
    comps_rq = ["player"],
  }
)

return {
  localPlayerNamePrefixIcon
}
