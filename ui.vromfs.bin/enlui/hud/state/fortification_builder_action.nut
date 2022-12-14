import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let {get_sync_time} = require("net")

let TIMER_DEFAULTS = {
  curProgress = -1.0
  totalTime = -1.0
  endTimeToComplete = -1.0
  actionTimerMul = 1
  actionTimerColor = Color(0, 0, 0, 0)
}

let actionTimer = Watched(clone TIMER_DEFAULTS)

let function resetState() {
  actionTimer(clone TIMER_DEFAULTS)
}

let destroyableBuildingsQuery = ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_destroy__timeToDestroy", ecs.TYPE_FLOAT],
    ["building_destroy__maxTimeToDestroy", ecs.TYPE_FLOAT],
    ["actionTimerColor", ecs.TYPE_POINT3]
  ],
  comps_no = ["undestroyableBuilding"]
})

let unfinishedBuildingsQuery = ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_builder__timeToBuild", ecs.TYPE_FLOAT],
    ["building_builder__maxTimeToBuild", ecs.TYPE_FLOAT],
    ["actionTimerColor", ecs.TYPE_POINT3]
  ],
})

let buildersQuery = ecs.SqQuery("buildingsQuery", {
  comps_ro = [
    ["building_action__target", ecs.TYPE_EID],
    ["human_weap__gunEids", ecs.TYPE_EID_LIST],
    ["entity_mods__timeToBuildMul", ecs.TYPE_FLOAT, 1.0]
  ],
  comps_no = ["deadEntity"]
})

let function trackComponents(_evt, _eid, _comp) {
  let hero = watchedHeroEid.value
  local herobuildingEid = ecs.INVALID_ENTITY_ID
  buildersQuery.perform(hero, function(_eid, buildersComps) {
    herobuildingEid = buildersComps["building_action__target"]
  })
  if (herobuildingEid == ecs.INVALID_ENTITY_ID) {
    resetState()
    return
  }
  local actionSpeed = 0.0
  buildersQuery.perform(function(_eid, buildersComps) {
    if (herobuildingEid == buildersComps["building_action__target"]){
      let scondaryGunEid = buildersComps["human_weap__gunEids"][weaponSlots.EWS_SECONDARY]
      let speed = ecs.obsolete_dbg_get_comp_val(scondaryGunEid,"engineerBuildingSpeedMul") ?? 1.0
      actionSpeed += speed * buildersComps["entity_mods__timeToBuildMul"]
    }
  })
  if (actionSpeed <= 0.0)
    return
  let curTime = get_sync_time()
  destroyableBuildingsQuery.perform(herobuildingEid, function(_eid, buildingComps) {
    let maxTimeToDestroy = buildingComps["building_destroy__maxTimeToDestroy"]
    if (maxTimeToDestroy <= 0.0)
      return
    let timeToDestroy = buildingComps["building_destroy__timeToDestroy"]
    let totalDestroyTime = timeToDestroy / actionSpeed
    let realTimeToCompleteBuild = curTime + totalDestroyTime
    let color = buildingComps.actionTimerColor
    actionTimer.mutate(function (v) {
      v.curProgress = timeToDestroy / maxTimeToDestroy
      v.totalTime = totalDestroyTime
      v.endTimeToComplete = realTimeToCompleteBuild
      v.actionTimerMul = -1 * v.curProgress
      v.actionTimerColor = Color(color.x, color.y, color.z, 0)
    })
  })
  unfinishedBuildingsQuery.perform(herobuildingEid, function(_eid, buildingComps) {
    let maxTimeToBuild = buildingComps["building_builder__maxTimeToBuild"]
    if (maxTimeToBuild <= 0.0)
      return
    let timeToBuild = buildingComps["building_builder__timeToBuild"]
    let totalBuildTime = (maxTimeToBuild - timeToBuild) / actionSpeed
    let realTimeToCompleteBuild = curTime + totalBuildTime
    let color = buildingComps.actionTimerColor
    actionTimer.mutate(function (v) {
      v.curProgress = timeToBuild / maxTimeToBuild
      v.totalTime = totalBuildTime
      v.endTimeToComplete = realTimeToCompleteBuild
      v.actionTimerMul = 1 - v.curProgress
      v.actionTimerColor = Color(color.x, color.y, color.z, 0)
    })
  })
}

ecs.register_es("buildings_destroyer_ui_es", {
  onChange = trackComponents
},
{
  comps_track = [
    ["building_action__target", ecs.TYPE_EID],
  ]
})

ecs.register_es("buildings_destroyer_reset_ui_es", {
  onDestroy = @(...) resetState()
},
{
  comps_rq = ["hero", "building_action__target"]
  comps_no = ["deadEntity"]
})

return {
  actionTimer
}