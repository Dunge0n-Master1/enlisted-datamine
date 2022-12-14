import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { tipCmp } = require("tipComponent.nut")

let isMortarMode = Watched(false)
let mortarDistance = Watched(0.0)
local mortarEid = ecs.INVALID_ENTITY_ID

let function trackMortarMode(_eid, comp) {
  let isActive = comp["human_weap__mortarMode"]
  isMortarMode(isActive)
  mortarEid = (isActive ? comp["human_weap__currentGunEid"] : null) ?? ecs.INVALID_ENTITY_ID
  let distance = ecs.obsolete_dbg_get_comp_val(mortarEid, "mortar__targetDistance", 0.0)
  if (distance > 0)
    mortarDistance(distance)
}

ecs.register_es("mortar_aiming_mode_es",
  {
    [["onInit", "onChange"]] = trackMortarMode
    onDestroy = @() isMortarMode(false)
  },
  {
    comps_track = [
      ["human_weap__mortarMode", ecs.TYPE_BOOL],
      ["human_weap__currentGunEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID]
    ]
    comps_rq = ["hero","watchedByPlr"]
  })

let function trackMortarDistance(eid, comp) {
  if (eid != mortarEid)
    return
  let distance = comp["mortar__targetDistance"]
  if (distance > 0)
    mortarDistance(distance)
}

ecs.register_es("mortar_aiming_distance_es",
  {
    [["onInit", "onChange"]] = trackMortarDistance
  },
  {
    comps_track = [["mortar__targetDistance", ecs.TYPE_FLOAT]]
  })

let mkAimDistance = @(distance) tipCmp({
  text = loc("hud/mortar_aiming", { distance = distance })
  inputId = "Human.Aim"
})

let function mortar() {
  let res = { watch = [isMortarMode, mortarDistance] }
  if (!isMortarMode.value)
    return res
  return res.__update({
    children = mkAimDistance(mortarDistance.value.tointeger())
  })
}

return mortar
