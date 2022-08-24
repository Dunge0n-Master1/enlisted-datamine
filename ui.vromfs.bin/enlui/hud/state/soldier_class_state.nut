import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let heroSoldierKind = Watched("")

ecs.register_es("ui_hero_soldier_class",
  {
    onInit = @(_eid, comp) heroSoldierKind(comp["soldier__sKind"]),
    onDestroy = @(...) heroSoldierKind("")
  },
  {
    comps_ro = [["soldier__sKind", ecs.TYPE_STRING]],
    comps_rq = ["hero"]
  }
)

return {
  heroSoldierKind
}