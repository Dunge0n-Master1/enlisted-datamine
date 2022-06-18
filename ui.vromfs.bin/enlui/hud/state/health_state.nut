import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

//=============hp_es=======
let hp = Watched()
let hpRestoreAmount = Watched()
let maxHp = Watched(0)
let scaleHp = Watched(0)
let isAliveState = Watched(false)
let isDownedState = Watched(false)
let isHealContinuousInput = Watched(true)

ecs.register_es("health_state_ui_es", {
  [["onChange", "onInit"]] = function trackComponentsHero(_eid,comp) {
    let isAlive = comp["isAlive"]
    let isDowned = comp["isDowned"]
    hp(isAlive ? comp["hitpoints__hp"] : null)
    hpRestoreAmount(isAlive ? comp["hitpoints_heal__restoreAmount"] : null)
    maxHp(!isDowned ? comp["hitpoints__maxHp"] : -comp["hitpoints__deathHpThreshold"])
    scaleHp(comp["hitpoints__scaleHp"])
    isAliveState.update(isAlive)
    isDownedState.update(isDowned)
    isHealContinuousInput(comp["heal__continuousInput"])
  }
  onDestroy = function(_eid, _comp){
    hp(null)
    hpRestoreAmount(0)
    scaleHp(0)
    isAliveState(false)
    isDownedState(false)
    isHealContinuousInput(true)
  }
}, {
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
