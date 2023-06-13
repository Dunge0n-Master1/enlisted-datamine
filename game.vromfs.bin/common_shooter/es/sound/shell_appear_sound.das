require ecs
require soundEvent
require AnimV20
require GeomNodeTree


[es(tag=sound, on_appear, REQUIRE_NOT=clientSide)]
def shell_appear_sound(evt : Event;
                       shell_appear_sound__name : string;
                       shell__owner : EntityId)
  // Why REQUIRE_NOT=clientSide?
  // Client-side shell tend to be suddenly destroyed, when the server-authoritated shell arrives
  // The lifetime of the server-authoritated shell is more predictable and consistent
  // Hence the server-autoritated shell is the one, producing sounds
  ecs::query(shell__owner) <| $ [es] (is_watched_sound : bool; animchar : AnimcharBaseComponent)
    let nodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, "weapon_right")
    if nodeIdx >= 0
      let pos = geomtree_getNodeWpos(*animchar.nodeTree, nodeIdx)
      oneshot(is_watched_sound ? "player/{shell_appear_sound__name}" : "enemy/{shell_appear_sound__name}", pos)
