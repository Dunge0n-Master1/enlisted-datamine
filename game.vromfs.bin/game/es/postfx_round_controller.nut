import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let { get_controlled_hero } = require("%dngscripts/common_queries.nut")
let { EventTeamRoundResult } = require("dasevents")
let {app_is_offline_mode} = require("app")

let function onRoundResult(evt, eid, comp) {
  if (app_is_offline_mode())
    return
  let heroTeam = ecs.obsolete_dbg_get_comp_val(get_controlled_hero() ?? ecs.INVALID_ENTITY_ID, "team", TEAM_UNASSIGNED)
  if (evt.team != heroTeam)
    return

  let postfx = comp["post_fx"]
  comp["postfx_round_ctrl__maxExposure"] = postfx?["adaptation__maxExposure"]
    ?? comp["postfx_round_ctrl__maxExposure"]
  postfx["adaptation__maxExposure"] <- 1000.0
  postfx["adaptation__minExposure"] = 0.001
  let expScale = evt.isWon
    ? comp["postfx_round_ctrl__scaleOnWin"]
    : comp["postfx_round_ctrl__scaleOnLose"];
  comp["postfx_round_ctrl__expScale"] = expScale
  postfx["adaptation__adaptUpSpeed"] = 1
  postfx["adaptation__adaptDownSpeed"] = 1
  ecs.recreateEntityWithTemplates({eid, addTemplates = [{template = "postfx_roundctrl_update", comps = ["postfx_round_ctrl_update"]}]})
}

let postfx_comps = {
  comps_rw = [
    ["post_fx", ecs.TYPE_OBJECT],
    ["postfx_round_ctrl__expScale", ecs.TYPE_FLOAT],
    ["postfx_round_ctrl__maxExposure", ecs.TYPE_FLOAT],
  ],
  comps_ro = [
    ["postfx_round_ctrl__scaleOnWin", ecs.TYPE_FLOAT, 1.15],
    ["postfx_round_ctrl__scaleOnLose", ecs.TYPE_FLOAT, 0.9],
  ]
}

ecs.register_es("postfx_round_ctrl_es", {
  [EventTeamRoundResult] = onRoundResult,
}, postfx_comps)


let function onUpdate(dt, _eid, comp){
  let post_fx = comp["post_fx"]
  let curScale = post_fx?["adaptation__autoExposureScale"] ?? 1.0
  post_fx["adaptation__autoExposureScale"] <- min(1000.0, curScale * comp["postfx_round_ctrl__expScale"] * dt * 5.0)
}

let updateComps = clone postfx_comps
updateComps.comps_rq <- ["postfx_round_ctrl_update"]

ecs.register_es(
  "postfx_round_ctrl_update_es",
  {onUpdate = onUpdate},
  updateComps,
  {updateInterval = 0.2, tags="render", before="postfx_round_ctrl_es"}
)
