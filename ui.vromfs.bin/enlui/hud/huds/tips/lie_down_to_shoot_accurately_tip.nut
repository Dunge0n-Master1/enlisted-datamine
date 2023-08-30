import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { curWeaponWeapType } = require("%ui/hud/state/hero_weapons.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")

let tipCountData = mkOnlineSaveData("ui/hud/lie_down_to_shoot", @() 0)
let shownTipCount = tipCountData.watch
let showTip = Watched(false)
let entityStopedShooting = Watched(0)
let entityIsCrawling = Watched(0)
let hasShownCurGame = mkWatched(persist, "hasShownCurGame", false)

const TIP_SHOW_TIME = 5
const TIP_SHOW_COUNT = 5

ecs.register_es("stoped_shooting",{
  [["onInit","onChange"]] = function(_eid,comp){
    entityStopedShooting(comp["human_weap__lastShotAtTime"])
  }
}, {comps_track=[["human_weap__lastShotAtTime", ecs.TYPE_FLOAT]],
      comps_rq=["watchedByPlr"]})

ecs.register_es("is_crawling_now",{
  [["onInit","onChange"]] = function(_eid,comp){
    entityIsCrawling(comp["human_net_phys__isCrawl"])
  }
  }, {comps_track=[["human_net_phys__isCrawl", ecs.TYPE_BOOL]],
        comps_rq=["watchedByPlr"]})

let needShowTip = Computed(@() curWeaponWeapType.value == "submachine_gun"
                                && !entityIsCrawling.value && shownTipCount.value < TIP_SHOW_COUNT
                                && !hasShownCurGame.value
                                && !inVehicle.value)

let function makeShowTipTrue() {
  if (!needShowTip.value)
    return
  showTip(true)
  tipCountData.setValue(shownTipCount.value + 1)
  gui_scene.resetTimeout(TIP_SHOW_TIME, @() hasShownCurGame(true))
}

 needShowTip.subscribe(function(tip) {
   if (tip){
     entityStopedShooting.subscribe(function(shootingTime) {
       if (shootingTime >= 10){
         gui_scene.resetTimeout(0.5 , makeShowTipTrue)
       }
     })
   }
   showTip(false)
 })

let machineGunTip = tipCmp({
  text = loc("hint/lieDownToShootAccurately")
  inputId = "Human.Crawl"
  style = {onAttach = @() gui_scene.setTimeout(TIP_SHOW_TIME, @() showTip(false))
           onDetach = @() hasShownCurGame(true)}
}.__update(fontBody))

let lie_down_to_shoot_accurately_tip = @() {
  watch = showTip
  children = showTip.value ? machineGunTip : null
}

return lie_down_to_shoot_accurately_tip