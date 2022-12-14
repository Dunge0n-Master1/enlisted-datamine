from "%enlSqGlob/ui_library.nut" import *

let { minimalistHud } = require("%ui/hud/state/hudOptionsState.nut")
let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {setTips} = require("%ui/hud/state/tips.nut")
let medkit_tip               = require("%ui/hud/huds/tips/medkit_tip.nut")
let aim_stamina_tip          = require("%ui/hud/huds/tips/low_stamina_aim_tip.nut")
let switch_soldier_tip       = require("%ui/hud/huds/tips/switch_soldier_tip.nut")
let downed_grenade_usage_tip = require("%ui/hud/huds/tips/downed_grenade_usage_tip.nut")
let downed_tip               = require("%ui/hud/huds/tips/downed_tip.nut")
let {swithAimBtnTip,
      aimRangeValuesTip}       = require("%ui/hud/huds/tips/aim_range_tips.nut")

let reload_tip               = require("%ui/hud/huds/tips/reload_tip.nut")
let medkit_usage             = require("%ui/hud/huds/tips/medkit_usage.nut")
let low_stamina_use_flask_tip= require("%ui/hud/huds/tips/low_stamina_use_flask_tip.nut")
let vehicle_under_water      = require("%ui/hud/huds/tips/vehicle_underwater.nut")
let burning_tip              = require("%ui/hud/huds/tips/burning_tip.nut")
let hold_breath_tip          = require("%ui/hud/huds/tips/hold_breath_tip.nut")
let redeploy_tip             = require("%ui/hud/huds/tips/redeploy_tip.nut")
let plane_redeploy_tip       = require("%ui/hud/huds/tips/plane_redeploy_tip.nut")
let prevent_reloading_tip    = require("%ui/hud/huds/tips/prevent_reloading_tip.nut")
let place_bipod_tip          = require("%ui/hud/huds/tips/place_bipod_tip.nut")
let open_parachute_tip       = require("huds/tips/open_parachute_tip.nut")
let mark_enemy_tip           = require("huds/tips/mark_enemy_tip.nut")
let mortar_aiming_tip        = require("%ui/hud/huds/tips/mortar_aiming_tip.nut")
let mortar_switch_shell_tip  = require("%ui/hud/huds/tips/mortar_switch_shell_type_tip.nut")
let {isAlive} = require("%ui/hud/state/health_state.nut")
let { canShowGameHudInReplay } = require("%ui/hud/replay/replayState.nut")

let fullTips = [
  {
    pos = [-fsh(25), fsh(25)]
    children = reload_tip
  }
  {
    pos = [fsh(30), fsh(25)]
    gap = hdpx(2)
    children = [
      mark_enemy_tip, swithAimBtnTip, hold_breath_tip, downed_grenade_usage_tip,
      switch_soldier_tip, medkit_tip, aim_stamina_tip, low_stamina_use_flask_tip,
      place_bipod_tip, prevent_reloading_tip,
      mortar_aiming_tip, mortar_switch_shell_tip, open_parachute_tip
    ]
  }
  { children = medkit_usage }
  { children = vehicle_under_water }
  {
    pos = [fsh(0), fsh(5)]
    children = [downed_tip, burning_tip, redeploy_tip, plane_redeploy_tip]
  }
  {
    pos = [fsh(-15), fsh(2)]
    children = aimRangeValuesTip
  }
]
let minTips = [
  {
    pos = [fsh(30), fsh(25)]
    gap = hdpx(2)
    children = [medkit_tip, mortar_aiming_tip]
  }
  { children = medkit_usage }
  { children = vehicle_under_water }
  {
    pos = [fsh(0), fsh(5)]
    children = [downed_tip, burning_tip]
  }
]

let function stips(...){
  setTips(!isAlive.value || !canShowGameHudInReplay.value ? []
    : forcedMinimalHud.value || minimalistHud.value ? minTips
    : fullTips)
}
stips()
foreach (option in [canShowGameHudInReplay, isAlive, forcedMinimalHud, minimalistHud])
  option.subscribe(stips)
