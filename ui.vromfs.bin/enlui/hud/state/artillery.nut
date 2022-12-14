import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { get_local_player_team } = require("%dngscripts/common_queries.nut")

let artilleryIsAvailable = Watched(false)
let artilleryAvailableAtTime = Watched(-1.0)
let aircraftRequestAvailableAtTime = Watched(-1.0)
let artilleryIsAvailableByLimit = Watched(true)
let wasArtilleryAvailableForSquad = Watched(false)
let isHeroRadioman = Watched(false)
let artilleryAvailableShellTypes = Watched([])

let function track(_eid, comp) {
  if (!comp.is_local)
    return
  artilleryIsAvailable(comp["artillery__available"])
  artilleryAvailableAtTime(comp["artillery__availableAtTime"])
  wasArtilleryAvailableForSquad(comp["artillery__wasAvailableForSquad"] != ecs.INVALID_ENTITY_ID)
}

ecs.register_es("artillery_ui", {
  onInit = track,
  onChange = track,
  onDestroy = function(_eid, comp) {
    if (!comp.is_local)
      return
    artilleryIsAvailable(false)
    artilleryAvailableAtTime(-1.0)
    wasArtilleryAvailableForSquad(false)
  }
},
{
  comps_track=[
    ["artillery__available", ecs.TYPE_BOOL],
    ["artillery__availableAtTime", ecs.TYPE_FLOAT],
    ["artillery__wasAvailableForSquad", ecs.TYPE_EID],
    ["is_local", ecs.TYPE_BOOL]
  ],
  comps_rq=["player"]
})

let function updateTeamAircraftRequestTimer(_evt, _eid, comp) {
  if (get_local_player_team() == comp["team__id"])
    aircraftRequestAvailableAtTime(comp["team__aircraftRequestAvailableAtTime"])
}

ecs.register_es("aircraft_request_ui", {
  onInit = updateTeamAircraftRequestTimer,
  onChange = updateTeamAircraftRequestTimer,
  onDestroy = function(_evt, _eid, _comp) {
    aircraftRequestAvailableAtTime(-1.0)
  }
},
{
  comps_track=[
    ["team__aircraftRequestAvailableAtTime", ecs.TYPE_FLOAT],
  ],
  comps_ro=[
    ["team__id", ecs.TYPE_INT]
  ]
})

ecs.register_es("artillery_ui_available_shell_types", {
  [["onInit", "onChange"]] = function(_, comp) {
    if (comp.is_local) {
      let db = ecs.g_entity_mgr.getTemplateDB()
      let types = comp["artillery__templates"].getAll().map(function(templateName) {
        let artilleryTemplate = db.getTemplateByName(templateName)
        return {
          name = artilleryTemplate?.getCompValNullable("artillery__name") ?? templateName
          radius = artilleryTemplate?.getCompValNullable("artillery_zone__radius") ?? 0.
          isLine = artilleryTemplate?.getCompValNullable("artillery__isLineShape") ?? false
          maxLength = artilleryTemplate?.getCompValNullable("artillery__maxLineLength") ?? 0.0
        }
      })
      artilleryAvailableShellTypes(types)
    }
  },
},
{
  comps_track=[["is_local", ecs.TYPE_BOOL], ["artillery__templates", ecs.TYPE_STRING_LIST]]
  comps_rq=["player"]
})

ecs.register_es("artillery_hero_state", {
  [["onInit", "onChange"]] = @(_evt, _eid, comp) isHeroRadioman(comp["human_weap__radioEid"] != ecs.INVALID_ENTITY_ID)
  onDestroy = @(...) isHeroRadioman(false)
},
{
  comps_track=[["human_weap__radioEid", ecs.TYPE_EID]],
  comps_rq=["hero"]
})

ecs.register_es("artillery_limit_ui",
  {
    [["onInit", "onChange"]] = function(_evt, _eid, comp) {
      if (comp["team__id"] != localPlayerTeam.value)
        return

      let currentArtillery = comp["artillery_limit__current"].getAll()
      let maxArtillery = comp["artillery_limit__max"].getAll()
      let len = maxArtillery.len()
      local availableByLimit = false

      for(local i = 0; i < len; ++i)
        availableByLimit = availableByLimit || currentArtillery[i] < maxArtillery[i]
      artilleryIsAvailableByLimit(availableByLimit)
    },
    onDestroy = function(_evt, _eid, comp) {
      if (comp["team__id"] == localPlayerTeam.value)
        artilleryIsAvailableByLimit(true)
    }
  },
  {
    comps_track=[["artillery_limit__current", ecs.TYPE_INT_LIST]],
    comps_ro=[
      ["team__id", ecs.TYPE_INT],
      ["artillery_limit__max", ecs.TYPE_INT_LIST],
    ],
  }
)

let artilleryAvailableTimeLeft = mkCountdownTimerPerSec(artilleryAvailableAtTime)
let aircraftRequestAvailableTimeLeft = mkCountdownTimerPerSec(aircraftRequestAvailableAtTime)
let artilleryIsReady = Computed(@() artilleryIsAvailable.value && artilleryAvailableTimeLeft.value <= 0 && artilleryIsAvailableByLimit.value)

return {
  artilleryAvailableTimeLeft = artilleryAvailableTimeLeft
  aircraftRequestAvailableTimeLeft = aircraftRequestAvailableTimeLeft
  artilleryIsReady = artilleryIsReady
  artilleryIsAvailable = artilleryIsAvailable
  wasArtilleryAvailableForSquad = wasArtilleryAvailableForSquad
  isHeroRadioman = isHeroRadioman
  artilleryIsAvailableByLimit
  artilleryAvailableShellTypes
}