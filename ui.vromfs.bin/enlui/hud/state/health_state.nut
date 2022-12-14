import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { EventGameSessionFinished, EventSessionFinished } = require("dasevents")

//=============hp_es=======
let defState = freeze({
  hp = null
  maxHp = 0
  scaleHp = 0
  isAliveState = false
  isDownedState = false
})

let {state, stateSetValue} = mkFrameIncrementObservable(defState,"state")

let hp = Computed(@() state.value.hp)
let maxHp = Computed(@() state.value.maxHp)
let scaleHp = Computed(@() state.value.scaleHp)
let isAliveState = Computed(@() state.value.isAliveState)
let isDownedState = Computed(@() state.value.isDownedState)


local currentWatchedEid = ecs.INVALID_ENTITY_ID

ecs.register_es("health_state_ui_es", {
  [["onChange", "onInit"]] = function trackComponentsHero(eid,comp) {
    currentWatchedEid = eid
    let isAlive = comp["isAlive"]
    let isDowned = comp["isDowned"]
    stateSetValue({
      hp = isAlive ? comp["hitpoints__hp"] : null
      maxHp = !isDowned ? comp["hitpoints__maxHp"] : -comp["hitpoints__deathHpThreshold"]
      scaleHp = comp["hitpoints__scaleHp"]
      isAliveState = isAlive
      isDownedState = isDowned
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
  ]
  comps_rq=["watchedByPlr"]
})


let needDisplayHealTip = Watched(false)

ecs.register_es("track_is_need_heal_ui_es", {
  [["onChange", "onInit"]] = @(_eid, comp) needDisplayHealTip(comp.human_medkit__needDisplayHealTip)
  onDestroy = @(...) needDisplayHealTip(false)
},
{
  comps_track = [
    ["human_medkit__needDisplayHealTip", ecs.TYPE_BOOL],
  ]
  comps_rq=["watchedByPlr"]
})


//=====export====
return {
  isAlive = isAliveState
  isDowned = isDownedState
  hp
  maxHp
  scaleHp
  needDisplayHealTip
}
