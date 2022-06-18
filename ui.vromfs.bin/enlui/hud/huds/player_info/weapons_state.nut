from "%enlSqGlob/ui_library.nut" import *

let { curWeapon } = require("%ui/hud/state/hero_state.nut")

let totalAmmo = Computed(@() curWeapon.value?.totalAmmo ?? 0)
let isReloadable = Computed(@() curWeapon.value?.isReloadable ?? ((curWeapon.value?.maxAmmo ?? 0) > 0))
let curAmmo = Computed(@() curWeapon.value?.curAmmo ?? 0)
let additionalAmmo = Computed(@() curWeapon.value?.additionalAmmo ?? 0)
let isDualMagGun = Computed(@() curWeapon.value?.isDualMagGun ?? false)
let altCurAmmo = Computed(@() curWeapon.value?.altCurAmmo ?? 0)
let altTotalAmmo = Computed(@() curWeapon.value?.altTotalAmmo ?? 0)
let isModActive = Computed(@() curWeapon.value?.isModActive ?? false)
let weaponName = Computed(@() curWeapon.value?.name ?? "")
let firingMode = Computed(@() curWeapon.value?.firingMode ?? "")
let showWeaponBlock = Computed(@() curWeapon.value != null && !curWeapon.value?.isRemoving
      && (curWeapon.value?.changeProgress ?? 100) == 100)
let hasAltShot = Computed(@() curWeapon.value?.hasAltShot ?? false)

return {
  hasWeapon = Computed(@() curWeapon.value != null)
  curWeaponName = weaponName
  curWeaponAmmo = curAmmo
  curWeaponTotalAmmo = totalAmmo
  curWeaponIsDualMag = isDualMagGun
  curWeaponAdditionalAmmo = additionalAmmo
  curWeaponAltAmmo = altCurAmmo
  curWeaponAltTotalAmmo = altTotalAmmo
  curWeaponIsModActive = isModActive
  curWeaponIsReloadable = isReloadable
  curWeaponFiringMode = firingMode
  curWeaponHasAltShot = hasAltShot
  showWeaponBlock = showWeaponBlock
}
