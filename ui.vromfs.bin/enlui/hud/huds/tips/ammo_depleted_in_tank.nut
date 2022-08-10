from "%enlSqGlob/ui_library.nut" import *

let {inGroundVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {mainTurretAmmo} = require("%ui/hud/state/vehicle_turret_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let style = require("%ui/hud/style.nut")

let showTip = Watched(true)

let tipAmmoCurDepleted = tipCmp({
  text = loc("resupply/ammo_depleted", "Ammo depleted")
  textColor = style.HUD_TIPS_FAIL_TEXT_COLOR
  size = SIZE_TO_CONTENT
  style = {onAttach = @() gui_scene.setTimeout(6, @() showTip(false))}
})

let tipEngineerAmmoDepleted = tipCmp({
  text = loc("resupply/engineer_ammo_depleted", "Ammunition replenish by engineer required")
  textColor = style.HUD_TIPS_FAIL_TEXT_COLOR
  size = SIZE_TO_CONTENT
  style = {onAttach = @() gui_scene.setTimeout(6, @() showTip(false))}
})


let tipAmmoTotalDepleted = tipCmp({
  text = loc("resupply/ammo_total_depleted", "All ammo depleted")
  textColor = style.HUD_TIPS_FAIL_TEXT_COLOR
  size = SIZE_TO_CONTENT
})

let isAmmoCurrentTurretDepleted =
  Computed(@() inGroundVehicle.value && mainTurretAmmo.value?.curAmmo != null && mainTurretAmmo.value.curAmmo <= 1
              && mainTurretAmmo.value?.totalAmmo != null && mainTurretAmmo.value.totalAmmo <= 1)
let isAmmoTotalDepleted = Computed(@() inGroundVehicle.value && mainTurretAmmo.value?.ammoByBullet
  .findindex(@(ammo) ammo > 0) == null)

let canBeResuppliedOnPoint = Computed(@() mainTurretAmmo.value?.canBeResuppliedOnPoint ?? true)
let canBeResuppliedByEngineer = Computed(@() mainTurretAmmo.value?.canBeResuppliedByEngineer ?? false)

isAmmoCurrentTurretDepleted.subscribe( @(tip) tip ? showTip(true) : null)

let function ammo_depleted(){
  let res = {
    watch = [isAmmoCurrentTurretDepleted,
             isAmmoTotalDepleted,
             showTip,
             canBeResuppliedOnPoint,
             canBeResuppliedByEngineer]
  }
  if (!isAmmoCurrentTurretDepleted.value){
    return res
  }
  if (!isAmmoTotalDepleted.value){
    return res.__update({
      children = showTip.value ?
        [
          canBeResuppliedOnPoint.value ? tipAmmoCurDepleted : null
          canBeResuppliedByEngineer.value ? tipEngineerAmmoDepleted : null
        ]
        : null
    })
  }
  return res.__update({
    children = [
      canBeResuppliedOnPoint.value ? tipAmmoTotalDepleted : null
      canBeResuppliedByEngineer.value ? tipEngineerAmmoDepleted : null
    ]
  })
}

return ammo_depleted