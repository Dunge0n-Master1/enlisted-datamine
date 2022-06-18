import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { ACTION_REVIVE_TEAMMATE } =  require("hud_actions")

let canHealSelectedSoldier = Watched(false)
let heroMedicMedpacks = Watched(0)

ecs.register_es("medic_can_heal_soldier",
  {
    [["onInit", "onChange"]] = @(_eid, comp) canHealSelectedSoldier(
      comp.medic__canHealSelectedSoldier && comp.useActionAvailable != ACTION_REVIVE_TEAMMATE),
    onDestroy = @(...) canHealSelectedSoldier(false)
  },
  {
    comps_track = [
      ["medic__canHealSelectedSoldier", ecs.TYPE_BOOL],
      ["useActionAvailable", ecs.TYPE_INT]
    ],
    comps_rq = ["hero"],
    comps_no = ["deadEntity"]
  }
)

ecs.register_es("medic_heal_medpacks",
  {
    [["onInit", "onChange"]] = @(_eid, comp) heroMedicMedpacks(comp.total_kits__targetOnlyHeal)
  },
  {
    comps_track = [["total_kits__targetOnlyHeal", ecs.TYPE_INT]],
    comps_rq = ["hero"]
  }
)

return {
  canHealSelectedSoldier
  heroMedicMedpacks
}