import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sendNetEvent, RequestSquadFormation } = require("dasevents")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")
let { SquadFormationSpread } = require("%enlSqGlob/dasenums.nut")
let { find_local_player } = require("%dngscripts/common_queries.nut")

let savedSquadFormationOrders = get_setting_by_blk_path("ai/squadFormationOrder") ?? {}
let DEFAULT_FORMATION = SquadFormationSpread.ESFN_STANDARD
let squadFormation = Watched(DEFAULT_FORMATION)


let function applyNewFormation(squadEid, formation) {
  sendNetEvent(squadEid, RequestSquadFormation({spread=formation}))
  squadFormation(formation)
}

let function saveSquadFormation(squadProfileId, formation) {
  savedSquadFormationOrders[squadProfileId] <- formation
  set_setting_by_blk_path("ai/squadFormationOrder", savedSquadFormationOrders)
  save_settings()
}


let heroSquadEidQuery = ecs.SqQuery("heroSquadEidQuery", {
  comps_ro=[["squad_member__squad", ecs.TYPE_EID]]
})

let squadProfileIdQuery = ecs.SqQuery("squadProfileIdQuery", {
  comps_ro=[["squad__squadProfileId", ecs.TYPE_STRING]]
})

let function setSquadFormation(formation) {
  heroSquadEidQuery(controlledHeroEid.value, function(_, comp) {
    let squadEid = comp.squad_member__squad
    applyNewFormation(squadEid, formation)
    squadProfileIdQuery(squadEid, @(_, comp) saveSquadFormation(comp.squad__squadProfileId, formation))
  })
}


let function applyFormationOrderOnSpawnSquad(_evt, eid, comp) {
  if (comp.squad__ownerPlayer == ecs.INVALID_ENTITY_ID || comp.squad__ownerPlayer != find_local_player())
    return
  let squadProfileId = comp.squad__squadProfileId

  if (squadProfileId in savedSquadFormationOrders)
    applyNewFormation(eid, savedSquadFormationOrders[squadProfileId])
  else
    squadFormation(DEFAULT_FORMATION)
}

ecs.register_es("apply_squad_formation_order_es", {
    [[ecs.EventEntityCreated, ecs.EventComponentsAppear]] = applyFormationOrderOnSpawnSquad
  },
  { comps_ro = [["squad__squadProfileId", ecs.TYPE_STRING], ["squad__ownerPlayer", ecs.TYPE_EID]] },
  { tags = "gameClient" }
)

return {
  setSquadFormation
  squadFormation
}
