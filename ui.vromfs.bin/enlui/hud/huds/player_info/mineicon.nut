from "%enlSqGlob/ui_library.nut" import *

let mineIconNames = {
  antitank_mine = "item_antitank_mine.svg"
  antipersonnel_mine = "item_antipersonnel_mine.svg"
  tnt_block = "tnt_charge_icon.svg"
}

let MINES_ORDER = {
  tnt_block_exploder = 0
  antitank_mine = 1
  antipersonnel_mine = 2
}

let mineIcon = memoize(function(gType, size) {
  return Picture("ui/skin#{0}:{1}:{1}:K"
    .subst(mineIconNames?[gType] ?? mineIconNames.antitank_mine, size))
})

let mkMineIcon = memoize(@(mineType, size, color) mineType == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = mineIcon(mineType, size)
  color
})

return {
  MINES_ORDER
  mineIcon
  mkMineIcon
}
