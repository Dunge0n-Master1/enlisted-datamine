import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { EventHeroChanged } = require("gameevents")

/*
   TODO (grenades):
   * Optimize update (isEqual() replace state of grenades with list or table of Watched values)
   * Improve grenade slot in inventory screen
*/

let grenades = mkWatched(persist, "grenades", {})

let get_grenade_type_query = ecs.SqQuery("get_grenade_type_query", {
  comps_ro = [
    ["item__grenadeType", ecs.TYPE_STRING, null],
    ["item__grenadeLikeType", ecs.TYPE_STRING, null]
  ]
})

let function trackGrenades(_eid, comp) {
  let items = comp["itemContainer"]?.getAll() ?? []
  let newGrenades = {}
  foreach (item_eid in items) {
    let grenadeTypes = get_grenade_type_query(item_eid, @(_eid, gcomp) {
      gType = gcomp.item__grenadeType
      glType = gcomp.item__grenadeLikeType
    })
    if (grenadeTypes == null)
      continue
    if ([null, "shell"].indexof(grenadeTypes.gType) != null && grenadeTypes.glType == null)
      continue
    let grenadeType = grenadeTypes.gType ?? grenadeTypes.glType
    newGrenades[grenadeType] <- (newGrenades?[grenadeType] ?? 0) + 1
  }

  if (!isEqual(newGrenades, grenades.value)) {
    grenades(newGrenades)
  }
}

let function clearOnDestroy() {
  grenades({})
}

ecs.register_es("inventory_grenades_ui_es",
  {
    [["onInit", "onChange", "onUpdate", EventHeroChanged, ecs.sqEvents.EventRebuiltInventory]] = trackGrenades,
    onDestroy = clearOnDestroy,
  },
  {
    comps_rq = ["watchedByPlr"],
    comps_track = [["itemContainer", ecs.TYPE_EID_LIST]]
  },
  { updateInterval = 2, after="*", before="*" }
)

return {
  grenades = Computed(@() freeze(grenades.value))
}