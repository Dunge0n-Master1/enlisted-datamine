import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventEntityDied,EventOnSeatOwnersChanged} = require("dasevents")
let {localPlayerTeam, localPlayerGroupId} = require("%ui/hud/state/local_player.nut")
let {watchedHeroSquadEid} = require("%ui/hud/state/squad_members.nut")
let {INVALID_GROUP_ID} = require("matching.errors")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")

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

let isSquadmate = @(owner) owner.squad != INVALID_ENTITY_ID && owner.squad == watchedHeroSquadEid.value
let isGroupmate = @(owner) owner.groupId != INVALID_GROUP_ID && owner.groupId == localPlayerGroupId.value

let getPlayerInfoQuery = ecs.SqQuery("getPlayerInfoQuery",
  { comps_ro = [
      ["groupId", ecs.TYPE_INT64],
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING],
    ]
  })
let getEntityIsAliveQuery = ecs.SqQuery("getEntityIsAliveQuery", {comps_ro=[["isAlive", ecs.TYPE_BOOL, true]]})
let seatOwnerQuery = ecs.SqQuery("seatOwnerQuery", {comps_ro=["seat__ownerEid", "seat__squadEid", "seat__playerEid", "seat__isPlayer"]})

let getSitterInfo = @(seatEid) seatOwnerQuery.perform(seatEid, function(_,comp) {
  let squad = comp["seat__squadEid"]
  let playerEid = comp["seat__playerEid"]
  let isPlayer = comp["seat__isPlayer"]
  let eid = comp["seat__ownerEid"]
  let pInfo = getPlayerInfoQuery(playerEid, @(_, comp) comp)
  let { groupId = INVALID_GROUP_ID, name = null } = pInfo
  let isAlive = getEntityIsAliveQuery(eid, @(_, comp) comp.isAlive) ?? false
  return { eid, squad, groupId, isAlive, name = isPlayer ? name : null,
    nickFrame = pInfo?["decorators__nickFrame"]
  }
})
  ?? { eid = INVALID_ENTITY_ID, squad = INVALID_ENTITY_ID, groupId = INVALID_GROUP_ID,
    isAlive = false, name = null, nickFrame = null
  }

let function trackComps(eid, comp) {
  if (!comp.isAlive || comp.team != localPlayerTeam.value) {
    vehicle_markers_DestroyEid(eid)
    tank_markers_DestroyEid(eid)
    return
  }
  let aliveSitters = (comp["vehicle_seats__seatEids"]?.getAll() ?? []).map(getSitterInfo).
    filter(@(sitter) sitter.eid != INVALID_ENTITY_ID && sitter.isAlive)
  let groupmates = aliveSitters.filter(isGroupmate)
  let groupmatePlayerNames = groupmates
    .filter(@(s) s.name != null)
    .map(@(s) frameNick(remap_nick(s.name), s.nickFrame))
  let marker = {
    names = groupmatePlayerNames
    icon = comp["vehicle__mapIcon"]
    isEmpty = aliveSitters.len() == 0
    hasSquadmates = aliveSitters.findindex(isSquadmate) != null
    hasGroupmates = groupmates.len() > 0
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
    ["repairable__repairRequired", ecs.TYPE_BOOL],
  ]
}
let vehicleQuery = ecs.SqQuery("vehicleQuery", vehicle_comps)

ecs.register_es(
  "vehicle_markers_es",
  {
    [["onInit", "onChange", EventOnSeatOwnersChanged]] = trackComps
    onDestroy = function(_evt, eid, _comp) {
      vehicle_markers_DestroyEid(eid)
      tank_markers_DestroyEid(eid)
    }
  },
  vehicle_comps,
  {tags="gameClient"}
)

ecs.register_es(
  "vehicle_markers_track_seat_es",
  { onInit = @(_eid,comp) vehicleQuery.perform(comp["seat__vehicleEid"], trackComps) },
  { comps_ro = [["seat__vehicleEid", ecs.TYPE_EID]] },
  {tags="gameClient"}
)

ecs.register_es(
  "vehicle_markers_sitter_inited_or_died_es",
  { [[ecs.EventEntityCreated, EventEntityDied]] = @(_eid,comp) vehicleQuery.perform(comp["human_anim__vehicleSelected"], trackComps) },
  { comps_ro = [["human_anim__vehicleSelected", ecs.TYPE_EID]] },
  {tags="gameClient"}
)

return{
  vehicle_markers_Set,
  vehicle_markers_GetWatched,
  tank_markers_Set,
  tank_markers_GetWatched
}