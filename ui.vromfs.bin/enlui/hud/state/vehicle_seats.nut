import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventOnSeatOwnersChanged} = require("dasevents")

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let mkDefaultSeats = @() {
  data = []
}

let { vehicleSeats, vehicleSeatsSetValue, vehicleSeatsModify } = mkFrameIncrementObservable(mkDefaultSeats(), "vehicleSeats")

let getSeatsOrder = memoize(function() {
  let seatsOrderTpl = ecs.g_entity_mgr.getTemplateDB().getTemplateByName("vehicle_seats_order")
  return (seatsOrderTpl?.getCompValNullable("vehicleSeatsOrder").getAll() ?? [])
    .map(@(seat) seat?.name)
})

let getVehicleManualPlace = ecs.SqQuery("vehicle_seats_manual_query", {
  comps_ro = [["seats_order__canPlaceManually", ecs.TYPE_BOOL, false]]
})

let isHeroVehicleQuery = ecs.SqQuery("is_hero_vehicle_query", {
  comps_rq = [["heroVehicle"]]
})

let getVehicleSquad = ecs.SqQuery("vehicle_seats_squad_query", {
  comps_ro = [
    ["seat__ownerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["seat__playerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["seat__squadEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["seat__isPlayer", ecs.TYPE_BOOL, false]
  ]
})

let function trackComponents(_eid, comp) {
  let seatEids = comp["vehicle_seats__seatEids"].getAll() ?? []
  let seats = comp["vehicle_seats__seats"].getAll() ?? []
  let isSeatsSorted = comp["vehicle_seats__seatsProvideOrder"] != null

  local remap = array(seats.len()).map(@(_, idx) idx)
  if (!isSeatsSorted) {
    let ordered = []
    getSeatsOrder().each(function(orderId) {
      let idx = seats.findindex(@(seat) seat?.name == orderId)
      if (idx != null) {
        ordered.append(idx)
        let delIdx = remap.indexof(idx)
        if (delIdx != null)
          remap.remove(delIdx)
      }
    })
    remap = ordered.extend(remap)
  }

  let data = []
  foreach (i, idx in remap) {
    let seatEid = seatEids[idx]

    let orderDesc = {
      seatNo = i
      canPlaceManually = getVehicleManualPlace(seatEid, @(_, comp)
        comp["seats_order__canPlaceManually"])
    }

    let ownerDesc = getVehicleSquad(seatEid, @(_, comp) {
      eid      = comp["seat__ownerEid"]
      player   = comp["seat__playerEid"]
      squad    = comp["seat__squadEid"]
      isPlayer = comp["seat__isPlayer"]
    })

    data.append({
      seatNo = i
      owner = ownerDesc
      order = orderDesc
      seat = seats[idx]
    })
  }

  vehicleSeatsModify(function(v) {
    v.data = data
    return v
  })
}
ecs.register_es("vehicle_seats_ui_es",
  {
    [[EventOnSeatOwnersChanged, "onChange", "onInit"]] = trackComponents,
    onDestroy = @() vehicleSeatsSetValue(mkDefaultSeats())
  },
  {
    comps_track = [
      ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
      ["vehicle_seats__seats", ecs.TYPE_SHARED_ARRAY],
    ]
    comps_ro = [
      ["vehicle_seats__seatsProvideOrder", ecs.TYPE_TAG, null]
    ]
    comps_rq = ["vehicleWithWatched"]
  }
)

ecs.register_es("vehicle_seat_can_seat_changed_ui_es", {
  onChange = function (_eid, comp) {
    let isHeroVehicle = isHeroVehicleQuery(comp["seat__vehicleEid"], @(...) true) ?? false
    if (!isHeroVehicle)
      return

    let seatId = comp["seat__id"]
    let canPlaceManually = comp["seats_order__canPlaceManually"]
    vehicleSeatsModify(function(v) {
      v.data[seatId].order.canPlaceManually = canPlaceManually
      return v
    })
  }
},
{
  comps_track = [["seats_order__canPlaceManually", ecs.TYPE_BOOL]]
  comps_ro = [["seat__id", ecs.TYPE_INT], ["seat__vehicleEid", ecs.TYPE_EID]]
})

return vehicleSeats