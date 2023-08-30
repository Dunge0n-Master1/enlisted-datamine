import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

//=============breath_es=======
let breath_shortness = Watched()
let isHoldBreath = Watched(false)
let isHoldBreathAvailable = Watched(false)
let breath_low_anim_trigger = {}
let breath_low_threshold = 0.3

ecs.register_es("hero_breath_ui_es",
  {
    [["onChange", "onInit"]]= function trackComponentsBreath(_eid,comp){
      let isAlive = comp["isAlive"]
      if (!isAlive) {
        breath_shortness(null)
        isHoldBreath(false)
        isHoldBreathAvailable(false)
        anim_request_stop(breath_low_anim_trigger)
        return
      }
      isHoldBreath(comp["human_net_phys__isHoldBreath"])
      isHoldBreathAvailable(comp["human_hold_breath__isAvailable"])
      let timer = comp["human_breath__timer"]
      let max_hold_breath_time = comp["human_breath__maxHoldBreathTime"]
      let ratio = (timer>max_hold_breath_time || (max_hold_breath_time==0)) ? 0.0 : ((max_hold_breath_time - timer) / max_hold_breath_time)

      if (max_hold_breath_time == 0)
        breath_shortness(null)
      else
        breath_shortness(ratio)

      if (!(ratio > breath_low_threshold)) {
        anim_start(breath_low_anim_trigger)
      }
      else {
        anim_request_stop(breath_low_anim_trigger)
      }
    }

    function onDestroy() {
      breath_shortness(null)
      isHoldBreath(false)
      isHoldBreathAvailable(false)
    }
  },
  {
    comps_track = [
      ["human_breath__timer", ecs.TYPE_FLOAT, 0],
      ["isAlive", ecs.TYPE_BOOL, true],
      ["human_breath__maxHoldBreathTime", ecs.TYPE_FLOAT, 20.0],
      ["human_breath__recoverBreathMult", ecs.TYPE_FLOAT, 2.0],
      ["human_breath__asphyxiationTimer", ecs.TYPE_FLOAT, 0.0],
      ["human_hold_breath__isAvailable", ecs.TYPE_BOOL, false],
      ["human_net_phys__isHoldBreath", ecs.TYPE_BOOL, false],
    ]
    comps_rq = ["watchedByPlr"]
  }
)

//=====export====
return {
  breath_shortness
  breath_low_anim_trigger
  breath_low_threshold
  isHoldBreath
  isHoldBreathAvailable
}
