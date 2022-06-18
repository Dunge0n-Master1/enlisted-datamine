import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_action_handle, set_analog_stick_action_smooth_value} = require("dainput2")
let {EventHeroChanged} = require("gameevents")
let {aim_smooth} = require("%ui/hud/state/controls_online_storage.nut")

ecs.register_es("aim_smooth_apply_es",
  {
    [EventHeroChanged] = function onHeroChanged() {
      let act = get_action_handle("Human.Aim", 0xFFFF)
      if (act != 0xFFFF)
        set_analog_stick_action_smooth_value(act, aim_smooth.value)
    }
  },
  {},
  {tags="gameClient"}
)
