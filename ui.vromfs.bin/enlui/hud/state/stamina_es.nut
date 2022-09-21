import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let defValue = freeze({
  stamina = null
  scaleStamina = 0
  staminaCanAim = true
  staminaUseFlask = false
  lowStamina = false
})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let { stamina, scaleStamina, staminaCanAim, staminaUseFlask, lowStamina } = watchedTable2TableOfWatched(state)

ecs.register_es("hud_stamina_state_es",
  {
    [["onInit","onChange"]] = function(_, _eid, comp){
      stateSetValue({
        stamina = comp["view_stamina"]
        staminaCanAim = comp.human_weap__staminaCanAim
        lowStamina = comp["view_lowStamina"]
        scaleStamina = comp["entity_mods__staminaBoostMult"]
        staminaUseFlask = comp.view_stamina < comp.ui__flaskUseTipMinStamina
      })
    },
    function onDestroy(){
      stateSetValue(defValue)
    }
  },
  {
    comps_track = [
      ["view_stamina", ecs.TYPE_INT],
      ["view_lowStamina", ecs.TYPE_BOOL],
      ["entity_mods__staminaBoostMult", ecs.TYPE_FLOAT, 1.0],
      ["human_weap__staminaCanAim", ecs.TYPE_BOOL, true]
    ]
    comps_ro = [
      ["ui__flaskUseTipMinStamina", ecs.TYPE_FLOAT]
    ]
    comps_rq = ["watchedByPlr"]
  }
)

let staminaAnimTrigger = persist("staminaAnimTrigger", @() {})
lowStamina.subscribe(function(is_low) {
  if (is_low) {
    anim_start(staminaAnimTrigger)
  } else {
    anim_request_stop(staminaAnimTrigger)
  }
})

return {
  stamina, staminaAnimTrigger, scaleStamina, staminaCanAim, staminaUseFlask
}