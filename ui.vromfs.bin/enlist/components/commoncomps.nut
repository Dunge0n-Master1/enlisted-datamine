from "%enlSqGlob/ui_library.nut" import *
let {TextDefault} = require("%ui/style/colors.nut")

let emptyGap = freeze({
  size = [fsh(1), fsh(1)]
})

let horGap = freeze({
  size = [fsh(3), flex()], halign = ALIGN_CENTER, valign = ALIGN_CENTER
  children = { rendObj = ROBJ_SOLID, size = [hdpx(1),flex()], color = TextDefault, margin = [hdpx(4),0], opacity = 0.5 }
})

return {
  horGap
  emptyGap
}
