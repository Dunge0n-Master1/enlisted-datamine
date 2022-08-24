import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

//this is very good candidate to refactor - copy&paste is obvious

let sharedWatched = require("%dngscripts/sharedWatched.nut")

let levelLoaded = sharedWatched("levelLoaded", @() false)
let {EventUiShutdown} = require("dasevents")
ecs.register_es("level_state_ui_es",
  {
    [["onChange","onInit"]] = @(_eid, comp)  levelLoaded.update(comp["level__loaded"]),
    [EventUiShutdown] = @() levelLoaded.update(false),
    onDestroy = @() levelLoaded.update(false)
  },
  {comps_track = [["level__loaded", ecs.TYPE_BOOL]]}
)


let levelIsLoading = sharedWatched("levelIsLoading", @() false)
ecs.register_es("level_is_loading_ui_es",
  {
    [["onChange","onInit"]] = @(_eid, comp) levelIsLoading(comp["level_is_loading"])
    onDestroy = @() levelIsLoading.update(false)
  },
  {comps_track = [["level_is_loading", ecs.TYPE_BOOL]]}
)

let currentLevelBlk = Watched()
ecs.register_es("level_blk_name_ui_es",
  {
    [["onInit"]] = @(_eid, comp) currentLevelBlk(comp["level__blk"])
    onDestroy = @() currentLevelBlk.update(null)
  },
  {comps_ro = [["level__blk", ecs.TYPE_STRING]]}
)

let uiDisabled = Watched(false)
ecs.register_es("ui_disabled_ui_es",
  {
    [["onChange","onInit"]] = @(_eid, comp) uiDisabled.update(comp["ui__disabled"])
    onDestroy = @() uiDisabled.update(false)
  },
  {comps_track = [["ui__disabled", ecs.TYPE_BOOL]]}
)

let dbgLoading = mkWatched(persist, "dbgLoading", false)
console_register_command(function() {dbgLoading(!dbgLoading.value)},
  "ui.loadingDbg")


return {
  levelLoaded
  levelIsLoading
  uiDisabled //this is ugly, but we can't disabled HUD via absence of data
  currentLevelBlk
  dbgLoading
}
