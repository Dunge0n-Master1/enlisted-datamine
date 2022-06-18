from "%enlSqGlob/ui_library.nut" import *

let { canChangeCockpitView } = require("%ui/hud/state/cockpit.nut")
let vehicleSeats = require("%ui/hud/state/vehicle_seats.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp, mkInputHintBlock, defTipAnimations } = require("%ui/hud/huds/tips/tipComponent.nut")
let { inVehicle, inPlane, isSafeToExit, isPlayerCanExit, isVehicleAlive } = require("%ui/hud/state/vehicle_state.nut")

let allowHints = Computed(@() controlledHeroEid.value == watchedHeroEid.value
  && controlledHeroEid.value != INVALID_ENTITY_ID)

let showExitAloneAction = Computed(@()
  inVehicle.value
  && isPlayerCanExit.value
  && isVehicleAlive.value
  && (!inPlane.value || isSafeToExit.value))

let canHatch = Computed(function() {
  if (!allowHints.value)
    return false
  let ownerEid = controlledHeroEid.value
  let seat = vehicleSeats.value.data.findvalue(@(s) s?.owner.eid == ownerEid)
  return (seat?.seat.hatchNodes.len() ?? 0) > 0
})

let function exitVehicleAlone() {
  let res = { watch = showExitAloneAction }
  if (!showExitAloneAction.value)
    return res
  return res.__update({
    children = tipCmp({
      text = loc("hud/leaveVehicleAlone")
      inputId = "Human.ExitVehicleAlone"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

let function getOutOfTheTankHatch() {
  let res = { watch = canHatch }
  if (!canHatch.value)
    return res
  return res.__update({
    children = tipCmp({
      text = loc("watchFromTheTankHatch")
      inputId = "Human.ToggleHatch"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

let nextViewTip = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  transform = { pivot = [0.5,0.5] }
  animations = defTipAnimations

  children = [
    mkInputHintBlock("Vehicle.PrevCockpitView")
    tipCmp({
      inputId = "Vehicle.NextCockpitView"
      text = loc("lookTheOtherWay")
      textColor = DEFAULT_TEXT_COLOR
      animations = []
    })
  ]
}

let function nextView() {
  let res = { watch = [canChangeCockpitView, allowHints] }
  if (!canChangeCockpitView.value || !allowHints.value)
    return res
  return res.__update({ children = nextViewTip })
}

return [
  exitVehicleAlone
  getOutOfTheTankHatch
  nextView
]