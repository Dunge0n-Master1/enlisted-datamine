from "%enlSqGlob/ui_library.nut" import *

let grenadeIconNames = {
  antitank = "grenade_antitank_icon.svg"
  fougasse = "grenade_fougasse_icon.svg"
  impact = "impact_grenade_icon.svg"
  incendiary = "grenade_incendiary_icon.svg"
  flame = "grenade_flame_icon.svg"
  lunge_mine = "ni_05_lunge_mine.svg"
  tnt_block = "item_tnt_block_exploder.svg"
  smoke = "grenade_smoke_icon.svg"
}

let GRENADES_ORDER = {
  antitank = 0
  tnt_block = 1
  lunge_mine = 2
  impact = 3
  incendiary = 4
  fougasse = 5
  flame = 6
  smoke = 7
}

let grenadeIcon = memoize(function(gType, size) {
  return Picture("ui/skin#{0}:{1}:{1}:K"
    .subst(grenadeIconNames?[gType] ?? grenadeIconNames.fougasse, size))
})

let mkGrenadeIcon = memoize(@(grenadeType, size, color) grenadeType == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  color
  image = grenadeIcon(grenadeType, size)
})

return {
  GRENADES_ORDER
  grenadeIcon
  mkGrenadeIcon
}