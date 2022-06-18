import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
//local reviveItemsQuery = ecs.SqQuery("reviveItemsQuery", comps)
//todo - update items on team\player change. not likely to happen

let map_revive_items = Watched({})
let inventory_revive_items = Watched({})

let function clearEid(state, eid){
  if (eid in state.value){
    state.mutate(function(v) {
      delete v[eid]
    })
  }
}

ecs.register_es("map_items_to_revive_es",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (localPlayerTeam.value != comp["ressurectItemOwnerTeam"])
         return
      map_revive_items.mutate(function(v) {
         v[eid] <- {
           playerItemOwner=comp["playerItemOwner"],
           pos=comp["transform"][3],
         }
      })
   }
   onDestroy = @(eid, _comp) clearEid(map_revive_items, eid)
  },
  {
    comps_ro = [
      ["ressurectItemOwnerTeam", ecs.TYPE_INT],
      ["playerItemOwner", ecs.TYPE_EID, INVALID_ENTITY_ID]
    ],
    comps_track = [["transform", ecs.TYPE_MATRIX]],
    comps_rq= ["itemForResurrection"]
    comps_no= ["ui_visible"]
  }
)

ecs.register_es("inventory_items_to_revive_es",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (localPlayerTeam.value != comp["ressurectItemOwnerTeam"])
         return
      if (comp["playerItemOwner"] != INVALID_ENTITY_ID) {
        inventory_revive_items.mutate(@(v)
          v[eid] <- { playerItemOwner=comp["playerItemOwner"] })
      }
      else {
        clearEid(inventory_revive_items, eid)
      }
    },
    onDestroy = @(eid, _comp) clearEid(inventory_revive_items, eid)
  },
  {
    comps_ro = [
      ["ressurectItemOwnerTeam", ecs.TYPE_INT],
    ],
    comps_track = [["playerItemOwner", ecs.TYPE_EID, INVALID_ENTITY_ID]],
    comps_no = ["transform"],
    comps_rq = ["itemForResurrection"]
  }
)

return {
  map_revive_items
  inventory_revive_items
  team_has_revive_items = Computed(@() inventory_revive_items.value.len()>0)
}
