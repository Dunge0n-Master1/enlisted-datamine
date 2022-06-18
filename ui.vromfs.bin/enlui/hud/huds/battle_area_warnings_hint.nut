from "%enlSqGlob/ui_library.nut" import *

let displayOutsideBattleAreaWarning = require("%ui/hud/state/battle_area_warnings.nut")
let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")

return function () {
  let watch = displayOutsideBattleAreaWarning
  if (!displayOutsideBattleAreaWarning.value)
    return { watch = watch }

  return {
    watch = watch
    behavior = Behaviors.TextArea
    color = Color(255,180,180,200)
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    margin = fsh(20)
    text = loc("leftBattleArea")
  }.__update(h2_txt)
}