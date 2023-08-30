from "%enlSqGlob/ui_library.nut" import *

let {
  SquadBehaviour, SquadFormationSpread, SquadBehaviour_COUNT, SquadFormationSpread_COUNT
} = require("%enlSqGlob/dasenums.nut")
let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { HUD_TIPS_HOTKEY_FG } = require("%ui/hud/style.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")

let { setSquadFormation, squadFormation } = require("%ui/hud/state/squad_formation.nut")
let { setSquadBehaviour, squadBehaviour } = require("%ui/hud/state/squad_behaviour.nut")


let function textFunc(text) {
  return {
    fillColor = HUD_TIPS_HOTKEY_FG
    borderWidth = 0
    borderRadius = hdpx(2)
    size = SIZE_TO_CONTENT
    padding = [0, hdpx(3)]
    rendObj = ROBJ_BOX
    children = [
      {rendObj = ROBJ_TEXT text = text color=Color(0,0,0)}
    ]
  }
}

let mkStatus = @(action, children) watchElemState(@(sf) {
  behavior = isGamepad.value ? null : Behaviors.Button
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_HORIZONTAL
  VALIGN = ALIGN_CENTER
  padding = hdpx(5)
  gap = hdpx(10)
  color = sf & S_HOVER ? Color(200,200,200) : Color(240,240,240)
  onClick = action
  children
})


let squadBehaviourNames = {
  [SquadBehaviour.ESB_AGGRESSIVE] = loc("squad_orders/behaviour_aggressive", "Aggressive"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive", "Passive")
}

let squadBehaviourDescs = {
[SquadBehaviour.ESB_AGGRESSIVE] = loc("squad_orders/behaviour_aggressive/desc"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive/desc")
}

let currentSquadBehaviourText = Computed(@()
  loc("squad_orders/current_behaviour", {current=squadBehaviourNames[squadBehaviour.value]}))

let currentSquadBehaviourDescText = Computed(@() squadBehaviourDescs[squadBehaviour.value])

let selectNextBehaviour = @() setSquadBehaviour((squadBehaviour.value + 1) % SquadBehaviour_COUNT)

let changeBehaviour = mkStatus(selectNextBehaviour, [
  mkHotkey("E | J:Y", selectNextBehaviour, { textFunc })
  {
    flow = FLOW_VERTICAL
    children = [
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadBehaviourText
        text = currentSquadBehaviourText.value
      }.__update(fontBody)
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadBehaviourDescText
        text = currentSquadBehaviourDescText.value
      }.__update(fontSub)
    ]
  }
])


let squadFormationNames = {
  [SquadFormationSpread.ESFN_CLOSEST] = loc("squad_orders/formation_close", "Closest"),
  [SquadFormationSpread.ESFN_STANDARD] = loc("squad_orders/formation_standard", "Standard"),
  [SquadFormationSpread.ESFN_WIDE] = loc("squad_orders/formation_wide", "Wide")
}

let squadFormationDescs = {
  [SquadFormationSpread.ESFN_CLOSEST] = loc("squad_orders/formation_close/desc"),
  [SquadFormationSpread.ESFN_STANDARD] = loc("squad_orders/formation_standard/desc"),
  [SquadFormationSpread.ESFN_WIDE] = loc("squad_orders/formation_wide/desc")
}

let currentSquadFormationText = Computed(@()
  loc("squad_orders/current_formation", {current=squadFormationNames[squadFormation.value]}))

let currentSquadFormationDescText = Computed(@() squadFormationDescs[squadFormation.value])

let selectNextFormation = @() setSquadFormation((squadFormation.value + 1) % SquadFormationSpread_COUNT)

let changeFormation = mkStatus(selectNextFormation, [
  mkHotkey("Q | J:X", selectNextFormation, { textFunc })
  {
    flow = FLOW_VERTICAL
    children = [
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadFormationText
        text = currentSquadFormationText.value
      }.__update(fontBody)
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadFormationDescText
        text = currentSquadFormationDescText.value
      }.__update(fontSub)
    ]
  }
])

return {
  changeBehaviour
  changeFormation
}
