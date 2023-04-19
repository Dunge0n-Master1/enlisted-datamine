import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventHeroChanged} = require("gameevents")
let {get_sync_time} = require("net")

let exitVehicleState = mkWatched(persist, "exitVehicleState", {
  exitStartTime = 0.0
  exitTotalTime = 0.0
})

let enterVehicleState = mkWatched(persist, "enterVehicleState", {
  enterStartTime = 0.0
  enterTotalTime = 0.0
})

let function onExitTimerChanged(_eid, comp) {
  let timer = comp["exit_vehicle__atTime"]
  exitVehicleState.mutate(function (v) {
    v.exitStartTime = get_sync_time()
    v.exitTotalTime = timer >= 0 ? timer - v.exitStartTime : -1.0
  })
}

let function onEnterTimerChanged(_eid, comp) {
  let timer = comp["enter_vehicle__atTime"]
  enterVehicleState.mutate(function (v) {
    v.enterStartTime = get_sync_time()
    v.enterTotalTime = timer >= 0 ? timer - v.enterStartTime : -1.0
  })
}

let function onEndTimers(_eid, _comp) {
  enterVehicleState.mutate(@(v) v.enterTotalTime = -1.0)
  exitVehicleState.mutate(@(v) v.exitTotalTime = -1.0)
}

ecs.register_es("exit_vehicle_ui_es",
  {
    [["onInit", "onChange"]] = onExitTimerChanged,
    [EventHeroChanged] = onEndTimers
  },
  {
    comps_track = [["exit_vehicle__atTime", ecs.TYPE_FLOAT]],
    comps_rq = ["hero"]
    comps_no = ["human_vehicle__hideExitProgress"]
  }
)

ecs.register_es("enter_vehicle_ui_es",
  {
    [["onInit", "onChange"]] = onEnterTimerChanged,
    [EventHeroChanged] = onEndTimers
  },
  {
    comps_track = [["enter_vehicle__atTime", ecs.TYPE_FLOAT]],
    comps_rq = ["watchedByPlr"]
  }
)

return {
  enterVehicleState = enterVehicleState
  exitVehicleState = exitVehicleState
}