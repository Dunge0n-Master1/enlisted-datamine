import "%dngscripts/ecs.nut" as ecs
let eventbus = require("eventbus")
let { logerr } = require("dagor.debug")
let profiles = require("%enlSqGlob/data/all_tutorial_profiles.nut")

ecs.register_es("update_tutorial_profile_es",
  {
    onInit = function(_eid, comp) {
      let id = comp["tutorial__profile"]
      if (id not in profiles)
        logerr($"Not found tutorial.profile '{id}'")
      eventbus.send("updateArmiesData", profiles?[id] ?? {})
    }
  },
  { comps_ro=[["tutorial__profile", ecs.TYPE_STRING]] },
  { tags="gameClient" }
)
