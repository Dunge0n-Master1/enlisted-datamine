import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  vehicle_markers_Set,
  vehicle_markers_GetWatched,
  vehicle_markers_UpdateEid,
  vehicle_markers_DestroyEid
} = mkWatchedSetAndStorage("vehicle_markers_")

let {
  tank_markers_Set,
  tank_markers_GetWatched,
  tank_markers_UpdateEid,
  tank_markers_DestroyEid
} = mkWatchedSetAndStorage("tank_markers_")

let function trackComps(eid, comp) {
  if (!comp.isAlive || comp.team != localPlayerTeam.value) {
    vehicle_markers_DestroyEid(eid)
    tank_markers_DestroyEid(eid)
    return
  }
  let groupmateNickFrames = (comp.vehicle_marker_ui__gropmateNickFrames?.getAll() ?? [])
  let groupmateNames = (comp.vehicle_marker_ui__gropmateNames?.getAll() ?? []).map(@(name, i)
    frameNick(remap_nick(name), groupmateNickFrames?[i]))
  let marker = {
    names = groupmateNames
    icon = comp.vehicle__mapIcon
    isEmpty = comp.vehicle_marker_ui__isEmpty
    hasSquadmates = comp.vehicle_marker_ui__hasSquadmates
    hasGroupmates = comp.vehicle_marker_ui__hasGroupmates
    repairRequired = comp.repairable__repairRequired
  }
  vehicle_markers_UpdateEid(eid, marker)
  if (comp.isTank)
    tank_markers_UpdateEid(eid, marker)
}

let vehicle_comps = {
  comps_ro = [
    ["team", ecs.TYPE_INT],
    ["isAlive", ecs.TYPE_BOOL],
    ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
    ["repairable__repairRequired", ecs.TYPE_BOOL, false],
    ["vehicle__mapIcon", ecs.TYPE_STRING],
    ["isTank", ecs.TYPE_TAG, null],
  ]
  comps_track = [
    ["team", ecs.TYPE_INT],
    ["isAlive", ecs.TYPE_BOOL],
    ["vehicle_marker_ui__gropmateNickFrames", ecs.TYPE_STRING_LIST, null],
    ["vehicle_marker_ui__gropmateNames", ecs.TYPE_STRING_LIST, null],
    ["vehicle_marker_ui__isEmpty", ecs.TYPE_BOOL, false],
    ["vehicle_marker_ui__hasGroupmates", ecs.TYPE_BOOL, false],
    ["vehicle_marker_ui__hasSquadmates", ecs.TYPE_BOOL, false],
    ["repairable__repairRequired", ecs.TYPE_BOOL, false],
  ]
}

ecs.register_es(
  "vehicle_markers_es",
  {
    [["onInit", "onChange"]] = trackComps
    onDestroy = function(_evt, eid, _comp) {
      vehicle_markers_DestroyEid(eid)
      tank_markers_DestroyEid(eid)
    }
  },
  vehicle_comps,
  {tags="gameClient"}
)


return{
  vehicle_markers_Set,
  vehicle_markers_GetWatched,
  tank_markers_Set,
  tank_markers_GetWatched
}