import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {
  selectedBombSite,isBombPlanted,bombPlantedTimeEnd,bombResetTimeEnd,bombDefuseTimeEnd,
  bombTimeToPlant,bombTimeToResetPlant,bombTimeToDefuse
} = require("%ui/hud/state/selected_bomb_site_state.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")

let isPlanting = Computed(@() bombPlantedTimeEnd.value >= 0)
let bombTimeEnd = Computed(@()
  isBombPlanted.value ? bombDefuseTimeEnd.value
    : isPlanting.value ? bombPlantedTimeEnd.value
    : bombResetTimeEnd.value)
let bombTotalTime = Computed(@()
  isBombPlanted.value ? bombTimeToDefuse.value
    : isPlanting.value ? bombTimeToPlant.value
    : bombTimeToResetPlant.value)
let bombTimer = mkCountdownTimer(bombTimeEnd)
let bombProgress = Computed(@() bombTotalTime.value > 0 ? (1 - (bombTimer.value / bombTotalTime.value)) : 0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]
let indicatorSize = [hdpx(80), hdpx(80)]
let iconSz = hdpx(60)

let icon = freeze({
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#time_bomb.svg:{0}:{0}:K".subst(iconSz.tointeger()))
  size = [iconSz, iconSz]
})

let mkIndicator = @(fill = true) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon,
    {
      behavior = Behaviors.RtPropUpdate
      size = indicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * (fill ? bombProgress.value : (1.0 - bombProgress.value))
      }
    }
  ]
}

const PROGRESS_DIRECTION_FILL = true
const PROGRESS_DIRECTION_RESET = false
let plant_indicator = mkIndicator(PROGRESS_DIRECTION_FILL)
let reset_indicator = mkIndicator(PROGRESS_DIRECTION_RESET)
let defuse_indicator = mkIndicator(PROGRESS_DIRECTION_RESET)

return function () {
  return {
    watch = [selectedBombSite, isBombPlanted, isPlanting, bombProgress]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = selectedBombSite.value == ecs.INVALID_ENTITY_ID ? null
      : isBombPlanted.value ? defuse_indicator
      : isPlanting.value ? plant_indicator
      : reset_indicator
  }
}