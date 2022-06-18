import "%dngscripts/ecs.nut" as ecs
let {minimalistHud} = require("%ui/hud/state/hudOptionsState.nut")
let {EventLevelLoaded} = require("gameevents")

let setMinimalistHudQuery = ecs.SqQuery("setMinimalistHudQuery", {
  comps_rw = [["minimalistHud", ecs.TYPE_BOOL]]
})

let function setOrCreate(isMinimalistHud) {
  local found = false
  setMinimalistHudQuery.perform(function(_eid, comp) {
    found = true
    comp.minimalistHud = isMinimalistHud
  })

  if (!found)
    ecs.g_entity_mgr.createEntity("minimalist_hud_settings", { "minimalistHud": [isMinimalistHud, ecs.TYPE_BOOL] })
}

minimalistHud.subscribe(@(val) setOrCreate(val))

ecs.register_es("minimalist_hud_settings",
  { [EventLevelLoaded] = @(_evt, _eid, _comp) setOrCreate(minimalistHud.value) },
  {},
  {tags="gameClient"}
)