import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let steam = require_optional("steam")
let eventbus = require("eventbus")
let {EventWindowActivated, EventWindowDeactivated} = require("os.window")
let { nestWatched } = require("%dngscripts/globalState.nut")

let windowActive = nestWatched("windowActive", true)
let steamOverlayActive = nestWatched("steamOverlayActive", false)

ecs.register_es("os_window_activation_tracker",
  {
    [EventWindowActivated] = @(...) windowActive.update(true),
    [EventWindowDeactivated] = @(...) windowActive.update(false)
  })

eventbus.subscribe("steam.overlay_activation", @(params) steamOverlayActive.update(params.active))

if (steam) {
  steamOverlayActive.update(steam.is_overlay_active())
}

return {
  windowActive
  steamOverlayActive
}
