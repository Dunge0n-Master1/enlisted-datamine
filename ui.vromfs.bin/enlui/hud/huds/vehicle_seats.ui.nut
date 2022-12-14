import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let style = require("%ui/hud/style.nut")
let { watchedHeroSquadMembers } = require("%ui/hud/state/squad_members.nut")
let vehicleSeatsState = require("%ui/hud/state/vehicle_seats.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {controlHudHint} = require("%ui/components/controlHudHint.nut")
let getFramedNickByEid = require("%ui/hud/state/getFramedNickByEid.nut")

let NORMAL_HINT_SIZE = hdpx(20)
let GAMEPAD_HINT_SIZE = hdpx(36)

let colorBlue = Color(150, 160, 255, 180)

let memberTextColor = @(member) (member.eid == watchedHeroEid.value) ? style.SUCCESS_TEXT_COLOR
  : member.isAlive ? style.DEFAULT_TEXT_COLOR
  : style.DEAD_TEXT_COLOR

let function seatMember(seatDesc) {
  let { owner, seat, order } = seatDesc
  let locName = seat?.locName ?? (seat?.name ? $"vehicle_seats/{seat.name}" : null)
  let member = watchedHeroSquadMembers.value.findvalue(@(v) v.eid == owner.eid)
  local name = member?.name
  local color = member?.eid ? memberTextColor(member) : style.DEFAULT_TEXT_COLOR
  if (member == null) {
    if (owner.isPlayer)
      name = getFramedNickByEid(owner.player) ?? getFramedNickByEid(owner.eid)
    else if (owner.eid != ecs.INVALID_ENTITY_ID)
      name = ecs.obsolete_dbg_get_comp_val(owner.eid, "name") ?? "<Unknown>"
    if (name != null)
      color = colorBlue
  }
  let place = locName ? $"[{loc(locName)}]: " : ""
  name = name ?? (order.canPlaceManually ? loc("vehicle_seats/free_seat") : "...")
  return {
    rendObj = ROBJ_TEXT
    text = $"{place}{name}"
    color
  }.__update(sub_txt)
}

let mkEmptyHint = @(width) {
  size = [width, SIZE_TO_CONTENT]
}

let seatHint = @(seat, hintWidth) seat.order.canPlaceManually
  ? controlHudHint({
      id = $"Human.Seat0{seat.order.seatNo + 1}"
      size = [hintWidth, SIZE_TO_CONTENT]
      hplace = ALIGN_RIGHT
      text_params = sub_txt
    })
  : mkEmptyHint(hintWidth)

let function mkSeat(seat, isGpad) {
  let hintWidth = isGpad ? GAMEPAD_HINT_SIZE : NORMAL_HINT_SIZE
  return {
    rendObj = ROBJ_WORLD_BLUR
    flow = FLOW_HORIZONTAL
    padding = hdpx(2)
    gap = hdpx(5)
    children = [
      seatHint(seat, hintWidth)
      seatMember(seat)
    ]
    color = Color(220, 220, 220, 220)
  }
}
let hasVehicleSeats = Computed(@() vehicleSeatsState.value.data.len() > 0)

let function vehicleSeats() {
  let res = {
    watch = [hasVehicleSeats, watchedHeroSquadMembers, vehicleSeatsState, watchedHeroEid, isGamepad]
  }
  if (!hasVehicleSeats.value)
    return res

  return res.__update({
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    hplace = ALIGN_RIGHT
    padding = fsh(1)
    gap = hdpx(2)
    children = vehicleSeatsState.value.data.map(@(seat) mkSeat(seat, isGamepad.value))
  })
}

return vehicleSeats