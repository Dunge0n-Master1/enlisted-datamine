import "%dngscripts/ecs.nut" as ecs
let dagorMath = require("dagor.math")
let sqmath = require("%sqstd/math.nut")
//local cq = require("%dngscripts/common_queries.nut")

let function onStartHighlight(eid, comp) {
  if (comp["outline__enabled"])
    return
  comp["outline__enabled"] = true
  let setColor = sqmath.color2uint(255, 45, 45, 255) //get from UI components
  comp["outline__color"] = dagorMath.E3DCOLOR(setColor)
  local onTimer
  let timeout = 200.0
/*
  local avatarPos = ecs.obsolete_dbg_get_comp_val(cq.get_controlled_hero(), "transform")?.getcol?(3)
  if (avatarPos != null) {
    local lenSq = (comp.transform.getcol(3) - avatarPos).lengthSq()
    local rangeDistSq = [15*15,300*300]
    timeout = sqmath.lerp(rangeDistSq[0], rangeDistSq[1], 90, 200, clamp(lenSq, rangeDistSq[0],rangeDistSq[1]))
  }
*/
  onTimer = function(){
    if (ecs.g_entity_mgr.doesEntityExist(eid)) {
      let newColor = ecs.obsolete_dbg_get_comp_val(eid, "outline__color")
      if (newColor?.u == dagorMath.E3DCOLOR(setColor).u)//just to be sure that it is the color we set, not some else
        ecs.obsolete_dbg_set_comp_val(eid, "outline__enabled", false)
    }
    ecs.clear_callback_timer(onTimer)
  }
  ecs.set_callback_timer(onTimer, timeout, false)
}

let comps = {
  comps_rw = [
    ["outline__enabled", ecs.TYPE_BOOL],
    ["outline__color", ecs.TYPE_COLOR]
  //  only loot somehow
  ]
  comps_ro = [["transform", ecs.TYPE_MATRIX]]
}
ecs.register_es("team_item_highlighter_es", {
  [ecs.sqEvents.EventTeamItemHint] = onStartHighlight
}, comps, {tags  = "render"})
