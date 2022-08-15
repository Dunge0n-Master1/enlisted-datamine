from "%enlSqGlob/ui_library.nut" import *

let grenadeIconNames = {
  fougasse = "grenade_fougasse_icon.svg"
  antitank = "grenade_antitank_icon.svg"
  flame = "grenade_flame_icon.svg"
  flash = "grenade_flash_icon.svg"
  smoke = "grenade_smoke_icon.svg"
  impact = "impact_grenade_icon.svg"
  tnt_block = "item_tnt_block_exploder.svg"
}

let GRENADES_ORDER = {
  antitank = 0
  tnt_block = 1
  impact = 2
  fougasse = 3
  flame = 4
  smoke = 5
}

let grenadeIcon = memoize(function(gType, size) {
  return Picture("ui/skin#{0}:{1}:{2}:K"
    .subst(grenadeIconNames?[gType] ?? grenadeIconNames.fougasse, size[0], size[1]))
})

let mkGrenadeIcon = memoize(@(grenadeType, size) grenadeType == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = grenadeIcon(grenadeType, [size, size])
  tint = Color(220, 220, 220)
})

return {
  GRENADES_ORDER
  grenadeIcon
  mkGrenadeIcon
}