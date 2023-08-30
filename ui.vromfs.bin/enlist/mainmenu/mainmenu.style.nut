from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
return {
  navBottomBarHeight = hdpx(56)
  navHeight = calc_comp_size({size=SIZE_TO_CONTENT children={margin = [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(fontHeading2)})[1]
}