from "%enlSqGlob/ui_library.nut" import *

let {makeMarkersLayout} = require("%ui/components/hudMarkersLayout.nut")

let {active_grenades} = require("%ui/hud/state/active_grenades.nut")
let {active_bombs} = require("%ui/hud/state/active_bombs.nut")
let {shell_activators} = require("%ui/hud/state/shell_activators.nut")
let {fortificationPreviewForwardArrows} = require("%ui/hud/state/fortification_preview_forward_marker.nut")

let {grenade_marker} = require("%ui/hud/huds/hud_markers/grenade_ctor.nut")
let {bomb_marker} = require("%ui/hud/huds/hud_markers/bomb_ctor.nut")
let {activator_marker} = require("%ui/hud/huds/hud_markers/delayed_shell_activator_ctor.nut")

let {teammate_ctor} = require("hud_markers/teammate_ctor.nut")
let {teammatesAvatars} = require("%ui/hud/state/human_teammates.nut")

let {user_point_ctor} = require("hud_markers/user_points_ctor.nut")
let {user_point_mortar_dist_ctor} = require("%ui/_packages/common_shooter/hud/huds/hud_markers/user_points_mortar_dist_ctor.nut")
let {user_points} = require("%ui/hud/state/user_points.nut")

let squad_order_ctor = require("hud_markers/squad_order_ctor.nut")
let {squad_orders} = require("state/squad_orders.nut")
let watchedHeroSquadPersonalOrderCtor = require("hud_markers/squad_personal_order_ctor.nut")
let fortificationPreviewForwardIconCtor = require("hud_markers/fortification_preview_forward_ctor.nut")
let {watchedHeroSquadPersonalOrders} = require("state/squad_personal_orders.nut")

let {aircraft_markers} = require("state/aircraft_markers.nut")
let aircraft_ctor = require("hud_markers/aircraft_ctor.nut")

let {destroyable_ri_markers} = require("state/destroyable_score_ri_markers.nut")
let {destroyable_ri_ctor} = require("hud_markers/destroyable_score_ri_ctor.nut")

let {mine_markers} = require("state/mine_markers.nut")
let {mine_ctor} = require("hud_markers/mine_ctor.nut")

let useful_box_markers = require("state/useful_boxes.nut")
let simple_marker_ctor = require("hud_markers/simple_marker_ctor.nut")

let {friendly_tank_markers} = require("state/vehicle_markers.nut")
let tank_ctor = require("hud_markers/tank_ctor.nut")

let {spawn_zone_markers} = require("state/spawn_zones_markers.nut")
let spawn_zone_ctor = require("hud_markers/spawn_zone_ctor.nut")

let {hudMarkerEnable} = require("%ui/hud/state/hudOptionsState.nut")
let { forcedMinimalHud } = require("state/hudGameModes.nut")

let arrowsPadding = fsh(3)

let function hudUnder() {
  let markersCtorsAndState = {
    [squad_orders] = squad_order_ctor,
    [watchedHeroSquadPersonalOrders] = watchedHeroSquadPersonalOrderCtor,
    [fortificationPreviewForwardArrows] = fortificationPreviewForwardIconCtor,
    [destroyable_ri_markers] = destroyable_ri_ctor,
    [spawn_zone_markers] = spawn_zone_ctor,
    [teammatesAvatars] = teammate_ctor,
    [friendly_tank_markers] = tank_ctor,
  }

  if (hudMarkerEnable.value && !forcedMinimalHud.value) {
    markersCtorsAndState.__update({
      [aircraft_markers] = aircraft_ctor,
      [active_grenades] = grenade_marker,
      [shell_activators] = activator_marker,
      [active_bombs] = bomb_marker,
      [mine_markers] = mine_ctor,
      [useful_box_markers] = simple_marker_ctor,
    })
  }
  if (hudMarkerEnable.value) {
    markersCtorsAndState.__update({
      [user_points] = [user_point_ctor, user_point_mortar_dist_ctor],
    })
  }

  return {
    watch = [hudMarkerEnable, forcedMinimalHud]
    children = makeMarkersLayout(markersCtorsAndState, 1.2*arrowsPadding)
  }
}

return hudUnder
