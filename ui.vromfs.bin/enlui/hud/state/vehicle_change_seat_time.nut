import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_sync_time} = require("net")
let {EventOnStartVehicleChangeSeat,EventOnSeatOwnersChanged} = require("dasevents")
let {watchedTable2TableOfWatched} = require("%sqstd/frp.nut")

let defValue = freeze({
  switchSeatsEndTime = 0.0
  switchSeatsTotalTime = 0.0
})
let switchSeatsTimeState = mkWatched(persist, "switchSeatsTimeState", defValue)
let { switchSeatsEndTime, switchSeatsTotalTime } = watchedTable2TableOfWatched(switchSeatsTimeState)

ecs.register_es("vehicle_seats_on_chage_seat_ui_es",
  {
    [EventOnStartVehicleChangeSeat] = function(evt, _eid, _comp) {
      let endTime = evt.endTime
      let totalTime = max(0, endTime - get_sync_time())
      switchSeatsTimeState({
        switchSeatsEndTime = endTime
        switchSeatsTotalTime = totalTime
      })
    },
    [["onDestroy", EventOnSeatOwnersChanged]] = function() {
      switchSeatsTimeState(defValue)
    }
  },
  {
    comps_rq = ["heroVehicle"]
  }
)

return {switchSeatsEndTime, switchSeatsTotalTime}