from "%enlSqGlob/ui_library.nut" import *

let colors = {
  BulletDefault          = Color(50, 72, 74)
  BulletDefaultCurrent   = Color(82, 116, 117)
  MainAmmoColor          = Color(180, 180, 180)
  MainAmmoColorCurrent   = Color(240, 240, 240)
}
let function bulletOriginalColor(isEqupped) {
  return isEqupped ? colors.MainAmmoColorCurrent : colors.MainAmmoColor
}
let function bulletDefaultColor(isEqupped) {
  return isEqupped ? colors.BulletDefaultCurrent : colors.BulletDefault
}

let BULLET_TYPE = { //todo: use bullet icon from template
  DEFAULT = {
    prefix = null,
    icon = "tank/mashine_gun_ammo.svg"
    color = bulletDefaultColor
  }
  DEFAULT_CANNON = {
    prefix = null,
    icon = "tank/cannon_ammo_APHE.svg"
    color = bulletOriginalColor
  }
  AP = {
    prefix = "ap_"
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  APCBC_SOLID = {
    prefix = "apcbc_solid_"
    icon = "tank/cannon_ammo_APHE.svg"
    color = bulletOriginalColor
  }
  APC_SOLID = {
    prefix = "apc_solid_"
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  APHE = {
    prefix = "aphe_"
    icon = "tank/cannon_ammo_APHE.svg"
    color = bulletOriginalColor
  }
  APHEBC = {
    prefix = "aphebc_"
    icon = "tank/cannon_ammo_APHE.svg"
    color = bulletOriginalColor
  }
  APDS = {
    prefix = "apds_"
    icon = "tank/cannon_ammo_APDS.svg"
    color = bulletOriginalColor
  }
  APCR = {
    prefix = "apcr_"
    icon = "tank/cannon_ammo_APDS.svg"
    color = bulletOriginalColor
  }
  HE = {
    prefix = "he_"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  FRAG = {
    prefix = "frag_"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  SHRAPNEL = {
    prefix = "shrapnel"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  HEAT = {
    prefix = "heat_"
    icon = "tank/cannon_ammo_HEAT.svg"
    color = bulletOriginalColor
  }
  SMOKE = {
    prefix = "smoke"
    icon = "tank/cannon_ammo_smoke_shell.svg"
    color = bulletOriginalColor
  }
  FLAMETHROWER = {
    prefix = "flamethrower"
    icon = "tank/flamethrower_fuel.svg"
    color = bulletOriginalColor
  }
  PLASMA = {
    prefix = "plasma_"
    icon = "tank/cannon_ammo_HEAT.svg"
    color = bulletOriginalColor
  }
}

let function getBulletType(weapon) {
  if (weapon?.icon != null)
    return {
      icon = weapon?.icon
      color = bulletOriginalColor
    }
  if (weapon?.bulletType == null) //machine gun have no bullet type. For consistens, show machine gun bullets
    return BULLET_TYPE.DEFAULT

  return BULLET_TYPE.findvalue(@(bt) bt.prefix != null && (weapon?.bulletType.indexof(bt.prefix) ?? -1) == 0)
  ?? BULLET_TYPE.DEFAULT_CANNON //For consistens, show by default any cannon image
}

let getBulletImage = memoize(function(icn, w, h) {
  return Picture($"ui/skin#{icn}:{w}:{h}:K")
})

return function(weapon, size = [hdpxi(100), hdpxi(100)]) {
  let bulletType = getBulletType(weapon)

  return {
    icon = bulletType.icon
    image = getBulletImage(bulletType.icon, size[0], size[1])
    color = bulletType.color(weapon?.isCurrent ?? true)
  }
}