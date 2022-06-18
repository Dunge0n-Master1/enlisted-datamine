import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {showGameMenu} = require("%ui/hud/menus/game_menu.nut")
let {CmdShowHitcamera, EventOnHitCameraControlEvent,
       HITCAMERA_RENDER_READY, HITCAMERA_RENDER_DONE} = require("hitcamera")

let hitcameraEid = mkWatched(persist, "hitcameraEid")
let hitcameraTargetEid = mkWatched(persist, "hitcameraTargetEid")
let totalMembersBeforeShot = mkWatched(persist, "totalMembersBeforeShot", 0)
let deadMembers = mkWatched(persist, "deadMembers", 0)

let function showHitcamera(eid, target) {
  hitcameraEid(eid)
  hitcameraTargetEid(target)
  ecs.g_entity_mgr.sendEvent(eid, CmdShowHitcamera())
}

let function onInit(_evt, eid, comp) {
  comp["hitcamera__locked"] = true
  totalMembersBeforeShot(comp["hitcamera__totalMembersBeforeShot"])
  deadMembers(comp["hitcamera__deadMembers"])
  if (hitcameraEid.value != null) {
    // Stack up on the same target
    if (comp["hitcamera__target"] == hitcameraTargetEid.value)
      showHitcamera(eid, comp["hitcamera__target"])
    return
  }

  showHitcamera(eid, comp["hitcamera__target"])
}

let nextHitcameraQuery = ecs.SqQuery("nextHitcameraQuery", {
  comps_ro=[["hitcamera__target", ecs.TYPE_EID], ["hitcamera__renderState", ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
})
let function onDestroy(_evt, eid, _comp) {
  if (eid != hitcameraEid.value)
    return

  local nextTarget = null
  nextHitcameraQuery(function (nextEid, nextComp) {
    if ((nextTarget == null || nextComp["hitcamera__target"] == nextTarget) && nextComp["hitcamera__renderState"] == HITCAMERA_RENDER_READY) {
      showHitcamera(nextEid, nextComp["hitcamera__target"])
      nextTarget = nextComp["hitcamera__target"]
    }
  })

  if (nextTarget == null) {
    hitcameraEid(null)
    hitcameraTargetEid(null)
  }
}

let function onChange(_evt, _eid, comp) {
  let renderState = comp["hitcamera__renderState"]
  if (renderState == HITCAMERA_RENDER_DONE)
    comp["hitcamera__locked"] = false
}

let function onControlEvent(_evt, _eid, _comp) {
  // local target = evt[0]
  // local hitResult = evt[2]
}

ecs.register_es("hitcamera_ui_es", {
  onInit = onInit,
  onDestroy = onDestroy,
  onChange = onChange,
  [EventOnHitCameraControlEvent] = onControlEvent,
},
{
  comps_track=[["hitcamera__renderState", ecs.TYPE_INT],["hitcamera__target", ecs.TYPE_EID]]
  comps_rw=[["hitcamera__locked", ecs.TYPE_BOOL]]
  comps_ro=[["hitcamera__totalMembersBeforeShot", ecs.TYPE_INT], ["hitcamera__deadMembers", ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
},
{ tags="gameClient", before="hitcamera_destroy_non_locked_es", after="entities_in_victim_tank_es" })

return {
  hitcameraEid = hitcameraEid
  hitcameraTargetEid = hitcameraTargetEid
  isVisible = Computed(@() hitcameraEid.value != null && !showGameMenu.value)
  totalMembersBeforeShot = totalMembersBeforeShot
  deadMembers = deadMembers
}