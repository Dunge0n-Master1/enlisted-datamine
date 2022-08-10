import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { EventGameSessionFinished, EventSessionFinished } = require("dasevents")

//=============hp_es=======
let defState = freeze({
  hp = null
  hpRestoreAmount = 0
  maxHp = 0
  scaleHp = 0
  isAliveState = false
  isDownedState = false
  isHealContinuousInput = true
})

let {state, stateSetValue} = mkFrameIncrementObservable(defState,"state")

let hp = Computed(@() state.value.hp)
let hpRestoreAmount = Computed(@() state.value.hpRestoreAmount)
let maxHp = Computed(@() state.value.maxHp)
let scaleHp = Computed(@() state.value.scaleHp)
let isAliveState = Computed(@() state.value.isAliveState)
let isDownedState = Computed(@() state.value.isDownedState)
let isHealContinuousInput = Computed(@() state.value.isHealContinuousInput)


local currentWatchedEid = INVALID_ENTITY_ID

ecs.register_es("health_state_ui_es", {
  [["onChange", "onInit"]] = function trackComponentsHero(eid,comp) {
    currentWatchedEid = eid
    let isAlive = comp["isAlive"]
    let isDowned = comp["isDowned"]
    stateSetValue({
      hp = isAlive ? comp["hitpoints__hp"] : null
      hpRestoreAmount = isAlive ? comp["hitpoints_heal__restoreAmount"] : null
      maxHp = !isDowned ? comp["hitpoints__maxHp"] : -comp["hitpoints__deathHpThreshold"]
      scaleHp = comp["hitpoints__scaleHp"]
      isAliveState = isAlive
      isDownedState = isDowned
      isHealContinuousInput = comp["heal__continuousInput"]
    })
  }
  onDestroy = function(eid, _comp) {
    if (eid == currentWatchedEid)
      stateSetValue(defState)
  },
  [[EventGameSessionFinished, EventSessionFinished]] = function(_eid, _comp) { //< not sure about the events
    stateSetValue(defState)
  }
},
{
  comps_track = [
    ["hitpoints__hp", ecs.TYPE_FLOAT],
    ["hitpoints__maxHp", ecs.TYPE_FLOAT],
    ["hitpoints__scaleHp", ecs.TYPE_FLOAT],
    ["hitpoints__deathHpThreshold", ecs.TYPE_FLOAT, 0.0],
    ["isAlive", ecs.TYPE_BOOL, true],
    ["isDowned", ecs.TYPE_BOOL, false],
    ["hitpoints_heal__restoreAmount", ecs.TYPE_FLOAT, 0.0],
    ["heal__continuousInput", ecs.TYPE_BOOL, true],
  ]
  comps_rq=["watchedByPlr"]
})



//=====export====
return {
  isAlive = isAliveState
  isDowned = isDownedState
  hp
  hpRestoreAmount
  maxHp
  scaleHp
  isHealContinuousInput
}
