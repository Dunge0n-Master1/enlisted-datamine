import "%dngscripts/ecs.nut" as ecs

let { humanCapzoneCapturingSoundEnabled } = require("%ui/hud/state/sound_options_state.nut")

let setHumanCapzoneCapturingQuery = ecs.SqQuery("setHumanCapzoneCapturingQuery", {
  comps_rw = [["human__capzoneCapturingSoundEnabled", ecs.TYPE_BOOL]]
})

humanCapzoneCapturingSoundEnabled.subscribe(function(enabled) {
  setHumanCapzoneCapturingQuery(function(_eid, comp) {
    comp.human__capzoneCapturingSoundEnabled = enabled
  })
})
