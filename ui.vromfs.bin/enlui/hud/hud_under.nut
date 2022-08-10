from "%enlSqGlob/ui_library.nut" import *


let {main_user_point_ctor, enemy_user_point_ctor, enemy_vehicle_user_point_ctor, enemy_building_user_point_ctor} = require("hud_markers/user_points_ctor.nut")
let {user_point_mortar_dist_ctor} = require("%ui/hud/hud_markers/user_points_mortar_dist_ctor.nut")


let {teammates_markers_ctor} = require("hud_markers/teammate_ctor.nut")

let { squad_order_ctor } = require("hud_markers/squad_order_ctor.nut")
let { watched_hero_squad_personal_orders_ctor } = require("%ui/hud/hud_markers/squad_personal_order_ctor.nut")
let { grenade_ctor } = require("%ui/hud/hud_markers/grenade_ctor.nut")
let { bomb_ctor } = require("%ui/hud/hud_markers/bomb_ctor.nut")
let { activator_ctor } = require("%ui/hud/hud_markers/delayed_shell_activator_ctor.nut")
let { fortification_preview_forward_ctor } = require("hud_markers/fortification_preview_forward_ctor.nut")
let { destroyable_ri_ctor } = require("hud_markers/destroyable_score_ri_ctor.nut")
let { mine_ctor } = require("hud_markers/mine_ctor.nut")
let { useful_boxes_marker_ctor } = require("hud_markers/simple_marker_ctor.nut")
let { spawn_zone_ctor } = require("hud_markers/spawn_zone_ctor.nut")
let { aircraft_ctor } = require("hud_markers/aircraft_ctor.nut")
let { tank_ctor } = require("hud_markers/tank_ctor.nut")

let { hudMarkerEnable } = require("%ui/hud/state/hudOptionsState.nut")
let { forcedMinimalHud } = require("state/hudGameModes.nut")
let {horPadding, verPadding} = require("%enlSqGlob/safeArea.nut")

let function mkViewport(padding){
  return {
    sortOrder = -999
    size = [sw(100) - horPadding.value*2 - padding, sh(100) - verPadding.value*2 - padding]
    data = {
      isViewport = true
    }
  }
}

local function layout(state, ctor, padding){
  let child = mkViewport(padding)

  return function() {
    let children = [child]
    let res = ctor()
    children.extend(type(res) == "array" ? res : [res])
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = flex()
      children
      watch = state
      behavior = Behaviors.Projection
      sortChildren = true
    }
  }
}

let function makeMarkersLayout(stateAndCtors, padding){
  let layers = []
  foreach (sc in stateAndCtors) {
    let {watch, ctor} = sc
    layers.append(layout(watch, ctor, padding))
  }

  return @(){
    size = [sw(100), sh(100)]
    children = layers
    watch = [horPadding, verPadding]
  }
}

let arrowsPadding = fsh(3)

let function hudUnder() {
  let markersCtorsAndState = [
    destroyable_ri_ctor,
    squad_order_ctor,
    watched_hero_squad_personal_orders_ctor,
    fortification_preview_forward_ctor,
    spawn_zone_ctor, //optimize more
    tank_ctor
  ]

  if (hudMarkerEnable.value && !forcedMinimalHud.value) {
    markersCtorsAndState.append(
      aircraft_ctor,
      grenade_ctor,
      activator_ctor,
      bomb_ctor,
      mine_ctor,
      useful_boxes_marker_ctor,
    )
  }
  if (hudMarkerEnable.value) {
    markersCtorsAndState.append(
      main_user_point_ctor,
      enemy_user_point_ctor,
      enemy_vehicle_user_point_ctor,
      enemy_building_user_point_ctor,
      user_point_mortar_dist_ctor,
    )
  }
  markersCtorsAndState.append(teammates_markers_ctor)

  return {
    watch = [hudMarkerEnable, forcedMinimalHud]
    children = makeMarkersLayout(markersCtorsAndState, 1.2*arrowsPadding)
  }
}

return hudUnder
