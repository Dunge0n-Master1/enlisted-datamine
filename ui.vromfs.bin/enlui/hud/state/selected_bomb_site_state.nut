import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {controlledHeroEid} = require("%ui/hud/state/controlled_hero.nut")
let {EventHeroChanged} = require("gameevents")

let selectedBombSite = Watched(ecs.INVALID_ENTITY_ID)
let isBombPlanted = Watched(0.0)
let bombPlantedTimeEnd = Watched(0.0)
let bombResetTimeEnd = Watched(0.0)
let bombDefuseTimeEnd = Watched(0.0)
let bombTimeToPlant = Watched(0.0)
let bombTimeToResetPlant = Watched(0.0)
let bombTimeToDefuse = Watched(0.0)

selectedBombSite.subscribe(function(eid) {
  if (eid == ecs.INVALID_ENTITY_ID) {
    bombPlantedTimeEnd(0.0)
    bombResetTimeEnd(0.0)
  }
})

let function trackBombState(eid, comp) {
  if (eid == selectedBombSite.value) {
    isBombPlanted(comp["bomb_site__isBombPlanted"])
    bombPlantedTimeEnd(comp["bomb_site__plantedTimeEnd"])
    bombResetTimeEnd(comp["bomb_site__resetTimeEnd"])
    bombDefuseTimeEnd(comp["bomb_site__defusedTimeEnd"])
    bombTimeToPlant(comp["bomb_site__timeToPlant"])
    bombTimeToResetPlant(comp["bomb_site__timeToResetPlant"])
    bombTimeToDefuse(comp["bomb_site__timeToDefuse"])
  }
}

let function trackOperator(eid, comp) {
  if (eid == selectedBombSite.value && comp["bomb_site__operator"] != controlledHeroEid.value)
    selectedBombSite(ecs.INVALID_ENTITY_ID)
  else if (comp["bomb_site__operator"] == controlledHeroEid.value && controlledHeroEid.value != ecs.INVALID_ENTITY_ID) {
    selectedBombSite(eid)
    trackBombState(eid, comp)
  }
}

let bomb_site_comps = [
  ["bomb_site__isBombPlanted", ecs.TYPE_BOOL],
  ["bomb_site__plantedTimeEnd", ecs.TYPE_FLOAT],
  ["bomb_site__resetTimeEnd", ecs.TYPE_FLOAT],
  ["bomb_site__defusedTimeEnd", ecs.TYPE_FLOAT],
  ["bomb_site__timeToPlant", ecs.TYPE_FLOAT],
  ["bomb_site__timeToResetPlant", ecs.TYPE_FLOAT],
  ["bomb_site__timeToDefuse", ecs.TYPE_FLOAT],
]

ecs.register_es("track_operated_bomb",{
  [["onInit", "onChange"]] = trackOperator,
  [EventHeroChanged] = trackOperator,
  onDestroy = function(eid, _comp) {
    if (selectedBombSite.value == eid)
      selectedBombSite(ecs.INVALID_ENTITY_ID)
  }
  },
  {
    comps_track = [
      ["bomb_site__operator", ecs.TYPE_EID]
    ],
    comps_ro = bomb_site_comps
  },
  { tags="gameClient" }
)

ecs.register_es("track_operated_bomb_state",{
    [["onInit", "onChange"]] = trackBombState,
  },
  {
    comps_track = bomb_site_comps
  },
  { tags="gameClient" }
)

return {
  selectedBombSite
  isBombPlanted
  bombPlantedTimeEnd
  bombResetTimeEnd
  bombDefuseTimeEnd
  bombTimeToPlant
  bombTimeToResetPlant
  bombTimeToDefuse
}