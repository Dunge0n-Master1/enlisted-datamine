from "%enlSqGlob/ui_library.nut" import *

let mineIconNames = {
  antitank_mine = "item_antitank_mine.svg"
  antipersonnel_mine = "item_antipersonnel_mine.svg"
  tnt_block = "item_tnt_block_exploder.svg"
}

let MINES_ORDER = {
  antitank_mine = 0
  antipersonnel_mine = 1
  tnt_block_exploder = 2
}

let mineIcon = memoize(function(gType, size) {
  return Picture("ui/skin#{0}:{1}:{2}:K"
    .subst(mineIconNames?[gType] ?? mineIconNames.antitank_mine, size[0], size[1]))
})

let mkMineIcon = memoize(@(mineType, size) mineType == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = mineIcon(mineType, [size, size])
  tint = Color(220, 220, 220)
})

return {
  MINES_ORDER
  mineIcon
  mkMineIcon
}
