import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventOnStartVehicleChangeSeat,EventOnSeatOwnersChanged,CmdTrackVehicleWithWatched} = require("dasevents")
let {get_sync_time} = require("net")
let {watchedHeroEid} = require("%ui/hud/state/watched_hero.nut")

let DEFAULT_SEATS = {
  owners = []
  controls = []
  order = []
  seats = []
  data = []
  switchSeatsTime = 0.0
  switchSeatsTotalTime = 0.0
}

local seatsOrder = null

let function getSeatsOrder() {
  if (seatsOrder)
    return seatsOrder

  let seatsOrderTpl = ecs.g_entity_mgr.getTemplateDB().getTemplateByName("vehicle_seats_order")
  seatsOrder = (seatsOrderTpl?.getCompValNullable("vehicleSeatsOrder").getAll() ?? [])
    .map(@(seat) seat?.name)
  return seatsOrder
}

let vehicleSeats = mkWatched(persist, "vehicleSeats", clone DEFAULT_SEATS)

let function resetState() {
  vehicleSeats(DEFAULT_SEATS.__merge({ vehicle = INVALID_ENTITY_ID }))
}

let getChangeSeatsTime = ecs.SqQuery("vehicle_seats_change_query", {
  comps_ro = [["entity_mods__vehicleChangeSeatTimeMult"]]
})

let getVehicleControls = ecs.SqQuery("vehicle_seats_controls_query", {
  comps_ro = [["seat__availableControls"]]
})

let getVehicleManualPlace = ecs.SqQuery("vehicle_seats_manual_query", {
  comps_ro = [["seats_order__canPlaceManually", ecs.TYPE_BOOL, false]]
})

let isHeroVehicleQuery = ecs.SqQuery("is_hero_vehicle_query", {
  comps_rq = [["heroVehicle"]]
})

let getVehicleSquad = ecs.SqQuery("vehicle_seats_squad_query", {
  comps_ro = [
    ["seat__ownerEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["seat__playerEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["seat__squadEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
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

  let controls = []
  let order = []
  let owners = []
  let data = []
  foreach (i, idx in remap) {
    let seatEid = seatEids[idx]

    let controlsDesc = getVehicleControls(seatEid, @(_, comp)
      comp["seat__availableControls"]?.getAll()) ?? {}
    controls.append(controlsDesc)

    let orderDesc = {
      seatNo = i
      canPlaceManually = getVehicleManualPlace(seatEid, @(_, comp)
        comp["seats_order__canPlaceManually"])
    }
    order.append(orderDesc)

    let ownerDesc = getVehicleSquad(seatEid, @(_, comp) {
      eid      = comp["seat__ownerEid"]
      player   = comp["seat__playerEid"]
      squad    = comp["seat__squadEid"]
      isPlayer = comp["seat__isPlayer"]
    })
    owners.append(ownerDesc)

    data.append({
      seatNo = i
      owner = ownerDesc
      controls = controlsDesc
      order = orderDesc
      seat = seats[idx]
    })
  }

  vehicleSeats.mutate(function(v) {
    v.owners = owners
    v.controls = controls
    v.order = order
    v.seats = seats
    v.data = data
  })
}

ecs.register_es("vehicle_seats_ui_es",
  {
    onChange = trackComponents,
    onInit = trackComponents,
    onDestroy = resetState,
    [CmdTrackVehicleWithWatched] = trackComponents,
    [EventOnSeatOwnersChanged] = trackComponents,
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

ecs.register_es("vehicle_seats_on_chage_seat_ui_es",
  {
    [EventOnStartVehicleChangeSeat] = function(_eid, comp) {
      let curTime = get_sync_time()
      let timeMult = getChangeSeatsTime(watchedHeroEid.value, @(_, comp)
        comp["entity_mods__vehicleChangeSeatTimeMult"]) ?? 1.0
      let totalTime = comp["vehicle_seats_switch_time__totalSwitchTime"] * timeMult
      let deltaTime = curTime - vehicleSeats.value.switchSeatsTime
      if (deltaTime < totalTime)
        return;
      vehicleSeats.mutate(function(v) {
        v.switchSeatsTime = curTime
        v.switchSeatsTotalTime = totalTime
      })
    },
    [EventOnSeatOwnersChanged] = function() {
      vehicleSeats.mutate(function(v) {
        v.switchSeatsTime = 0
        v.switchSeatsTotalTime = 0
      })
    }
  },
  {
    comps_ro = [
      ["vehicle_seats_switch_time__totalSwitchTime", ecs.TYPE_FLOAT],
    ]
    comps_rq = ["heroVehicle"]
  }
)

ecs.register_es("vehicle_with_watched_changed_ui_es", {
  onInit = @(_eid, comp) ecs.g_entity_mgr.sendEvent(comp["human_anim__vehicleSelected"], CmdTrackVehicleWithWatched()),
  onChange = @(_eid, comp) ecs.g_entity_mgr.sendEvent(comp["human_anim__vehicleSelected"], CmdTrackVehicleWithWatched()),
},
{
  comps_track = [["human_anim__vehicleSelected", ecs.TYPE_EID]]
  comps_rq = ["watchedByPlr"]
})

ecs.register_es("vehicle_seat_can_seat_changed_ui_es", {
  onChange = function (_eid, comp) {
    let isHeroVehicle = isHeroVehicleQuery(comp["seat__vehicleEid"], @(...) true) ?? false
    if (!isHeroVehicle)
      return

    vehicleSeats.mutate(function(v) {
      let seatId = comp["seat__id"]
      v.order[seatId].canPlaceManually = comp["seats_order__canPlaceManually"]
      v.data[seatId].order.canPlaceManually = comp["seats_order__canPlaceManually"]
    })
  }
},
{
  comps_track = [["seats_order__canPlaceManually", ecs.TYPE_BOOL]]
  comps_ro = [["seat__id", ecs.TYPE_INT], ["seat__vehicleEid", ecs.TYPE_EID]]
})

return vehicleSeats