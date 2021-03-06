from "%enlSqGlob/ui_library.nut" import *

let iconSize = hdpx(22)

let itemTypesData = {
  boltaction_noscope = {
    svg = "rifle.svg"
    isWeapon = true
  }
  rifle_grenade_launcher = {
    svg = "rifle.svg"
    isWeapon = true
  }
  antitank_rifle = {
    svg = "launcher.svg"
    isWeapon = true
  }

  mgun = {
    svg = "machine_gun.svg"
    isWeapon = true
  }
  assault_rifle = {
    svg = "assault_rifle.svg"
    isWeapon = true
  }
  assault_rifle_stl = {
    svg = "assault_rifle.svg"
    isWeapon = true
  }

  submgun = {
    svg = "submachine_gun.svg"
    isWeapon = true
  }
  semiauto = {
    svg = "semiauto_rifle.svg"
    isWeapon = true
  }

  boltaction = {
    svg = "sniper_rifle.svg"
    isWeapon = true
  }
  semiauto_sniper = {
    svg = "sniper_rifle.svg"
    isWeapon = true
  }

  shotgun = {
    svg = "shotgun.svg"
    isWeapon = true
  }
  launcher = {
    svg = "launcher.svg"
    isWeapon = true
  }
  infantry_launcher = {
    svg = "launcher.svg"
    isWeapon = true
  }
  mortar = {
    svg = "mortarman.svg"
    isWeapon = true
  }
  flamethrower = {
    svg = "flametrooper.svg"
    isWeapon = true
  }

  vehicle = { svg = "tank_icon.svg" }
  tank = { svg = "tank_icon.svg" }
  bike = { svg = "bike_icon.svg" }
  aircraft = { svg = "aircraft_icon.svg" }
  assault_aircraft = { svg = "aircraft_icon.svg" }
  fighter_aircraft = { svg = "aircraft_icon.svg" }

  melee = { svg = "melee.svg" }
  medkits = { svg = "item_medkit.svg" }
  flask_usable = { svg = "flask_icon.svg" }
  grenade = { svg = "item_grenade.svg" }
  molotov = { svg = "grenade_flame_icon.svg" }
  smoke_grenade = { svg = "grenade_smoke_icon.svg" }
  explosion_pack = { svg = "explosion_pack_icon.svg" }
  impact_grenade = { svg = "impact_grenade_icon.svg" }
  mine = { svg = "item_antitank_mine.svg" }
  antipersonnel_mine = { svg = "item_antipersonnel_mine.svg" }
  antitank_mine = { svg = "item_antitank_mine.svg" }
  tnt_block = { svg = "item_tnt_block_exploder.svg" }
  tnt_block_exploder = { svg = "item_tnt_block_exploder.svg" }
  sideweapon = { svg = "item_pistol.svg" }
  reapair_kit = { svg = "item_reapair_kit.svg" }
  flaregun = { svg = "launcher.svg" }
  backpack = { svg = "item_backpack.svg" }
  binoculars_usable = { svg = "binoculars_icon.svg" }
}

let function itemTypeIcon(iType, iSubType = null, override = {}) {
  let img = itemTypesData?[iSubType].svg ?? itemTypesData?[iType].svg
  if (img == null)
    return null

  let imgSize = override?.size[0] ?? iconSize
  return {
    rendObj = ROBJ_IMAGE
    size = array(2, imgSize)
    image = Picture($"ui/skin#{img}:{imgSize}:{imgSize}:K")
  }.__update(override)
}

return {
  itemTypesData
  itemTypeIcon
}
