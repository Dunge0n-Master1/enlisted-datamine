import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { heroActiveResupplyZonesEids } = require("%ui/hud/state/resupplyZones.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {HUD_TIPS_FAIL_TEXT_COLOR} = require("%ui/hud/style.nut")

let tip = tipCmp({text = loc("resupply/tip"), textColor = HUD_TIPS_FAIL_TEXT_COLOR}.__update(body_txt))

let isResupplyTipShown = Watched(false)

let function resupplyTipTimer(){
  isResupplyTipShown(false)
}

const RESUPPLY_TIP_SHOW_TIME = 5

let function showResupplyTip() {
  if (isResupplyTipShown.value)
    gui_scene.clearTimer(resupplyTipTimer)
  isResupplyTipShown(true)
  gui_scene.setTimeout(RESUPPLY_TIP_SHOW_TIME, resupplyTipTimer)
}

let resupplyVehicleQuery = ecs.SqQuery("resupplyVehicleQuery", {comps_ro = [["turret_control__gunEids", ecs.TYPE_EID_LIST]] comps_rq = ["heroVehicle"]})

let function isShootingDry() {
  local isAnyTurretShooting = false

  resupplyVehicleQuery(function(_eid, comp) {
    let gunEids = comp["turret_control__gunEids"].getAll()
    for (local turretNo = 0; turretNo < gunEids.len(); ++turretNo) {
      let gunEid = gunEids[turretNo]

      let isShooting = ecs.obsolete_dbg_get_comp_val(gunEid, "turret_input__shootFlag") ?? false
      isAnyTurretShooting = isAnyTurretShooting || isShooting

      let gunAmmo = ecs.obsolete_dbg_get_comp_val(gunEid, "gun__ammo", 0)
      let gunTotalAmmo = ecs.obsolete_dbg_get_comp_val(gunEid, "gun__totalAmmo", 0)
      if (isShooting && (gunAmmo + gunTotalAmmo) > 0) {
        isAnyTurretShooting = false
        return false
      }
    }
  })

  return isAnyTurretShooting
}

let function trackComps() {
  if (heroActiveResupplyZonesEids.value.len() == 0)
    return
  if (isShootingDry())
    showResupplyTip()
}

ecs.register_es("turret_dry_shoot",
  { [["onInit", "onChange"]] = @(_evt, _eid, _comp) trackComps(),
  },
  {
    comps_track = [["turret_input__shootFlag", ecs.TYPE_BOOL]]
  }
)

return @() {
  flow = FLOW_HORIZONTAL
  watch = [isResupplyTipShown]
  children = isResupplyTipShown.value ? tip : null
}
