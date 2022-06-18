import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let stamina = Watched(null)
let lowStamina  = Watched(false)
let scaleStamina = Watched(0)
let staminaCanAim = Watched(true)
let staminaUseFlask = Watched(false)

ecs.register_es("hud_stamina_state_es",
  {
    [["onInit","onChange"]] = function(_eid, comp){
      stamina(comp["view_stamina"])
      lowStamina(comp["view_lowStamina"])
      staminaCanAim(comp.human_weap__staminaCanAim)
      scaleStamina(comp["entity_mods__staminaBoostMult"])
      staminaUseFlask(comp.view_stamina < comp.ui__flaskUseTipMinStamina)
    },
    function onDestroy(){
      stamina(null)
      lowStamina(null)
      staminaCanAim(true)
      scaleStamina(0)
      staminaUseFlask(false)
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

console_register_command(@(value) stamina(value), $"hud.stamina")


return {
  stamina, lowStamina, staminaAnimTrigger, scaleStamina, staminaCanAim, staminaUseFlask
}