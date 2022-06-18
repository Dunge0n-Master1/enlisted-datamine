import "%dngscripts/ecs.nut" as ecs
let narratorNativeLang = require("%enlSqGlob/narratorState.nut")
let {EventLevelLoaded} = require("gameevents")

let setNarratorNativeQuery = ecs.SqQuery("setNarratorNativeQuery", {
  comps_rw = [["narrator_settings__nativeLang", ecs.TYPE_BOOL]]
})

let setNative = @(isNative) setNarratorNativeQuery(@(_eid, comp) comp["narrator_settings__nativeLang"] = isNative)

narratorNativeLang.subscribe(@(val) setNative(val))

ecs.register_es("narrator_settings",
  { [EventLevelLoaded] = @(_evt, _eid, _comp) setNative(narratorNativeLang.value) },
  {},
  {tags="gameClient"}
)