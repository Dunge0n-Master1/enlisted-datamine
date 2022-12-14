import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let usefulBoxHintFull = Watched(null)
let usefulBoxHintEmpty = Watched(null)
let isUsefulBoxEmpty = Watched(false)
let selectedUsefulBox = Watched(ecs.INVALID_ENTITY_ID)

let usefulBoxQuery = ecs.SqQuery("usefulBoxQuery", {
  comps_ro = [
    ["useful_box__hintEmpty", ecs.TYPE_STRING],
    ["useful_box__hintFull", ecs.TYPE_STRING],
    ["useful_box__useCount", ecs.TYPE_INT],
    ["useful_box__anyTeam", ecs.TYPE_TAG, null],
    ["team", ecs.TYPE_INT],
  ]
})

ecs.register_es("ui_useful_box_hint_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let selectedObject = comp["human_use_object__selectedBuilding"]
      local hintFull = null
      local hintEmpty = null
      local isBoxEmpty = false
      local usefulBox = ecs.INVALID_ENTITY_ID
      usefulBoxQuery(selectedObject, function(eid, comp) {
        if (!comp.useful_box__anyTeam && !is_teams_friendly(localPlayerTeam.value, comp.team))
          return

        usefulBox = eid
        hintFull = comp["useful_box__hintFull"]
        hintEmpty = comp["useful_box__hintEmpty"]
        isBoxEmpty = (comp["useful_box__useCount"] == 0)
      })
      usefulBoxHintFull(hintFull)
      usefulBoxHintEmpty(hintEmpty)
      isUsefulBoxEmpty(isBoxEmpty)
      selectedUsefulBox(usefulBox)
    },
  },
  {
    comps_track = [["human_use_object__selectedBuilding", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  },
  { before="ui_useful_box_ammo_count_changed_es" }
)

ecs.register_es("ui_useful_box_ammo_count_changed_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      if (selectedUsefulBox.value == eid)
        isUsefulBoxEmpty(comp["useful_box__useCount"] == 0)
    },
  },
  {
    comps_track = [["useful_box__useCount", ecs.TYPE_INT]]
  }
)

return {
  usefulBoxHintFull
  usefulBoxHintEmpty
  isUsefulBoxEmpty
}