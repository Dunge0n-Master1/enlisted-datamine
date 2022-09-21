import "%dngscripts/ecs.nut" as ecs
let isDedicated = require_optional("dedicated") != null
let {exit_game, switch_to_menu_scene} = require("app")
let {EventTeamRoundResult, EventSessionFinished} = require("dasevents")

let function onRoundResult(eid, comp) {
  if (comp["is_session_finalizing"])
    return

  let exitFunc = isDedicated ? exit_game : switch_to_menu_scene

  comp["is_session_finalizing"] = true
  ecs.clear_timer({eid=eid, id="session_finalizing"})
  ecs.set_callback_timer(exitFunc, comp["session_finalizer__timer"], false)
  ecs.g_entity_mgr.broadcastEvent(EventSessionFinished())
}

let comps = {
  comps_rw = [["is_session_finalizing", ecs.TYPE_BOOL]],
  comps_ro = [["session_finalizer__timer", ecs.TYPE_FLOAT, 10.0]]
}

ecs.register_es("session_finalizer_es", {
    [EventTeamRoundResult] = onRoundResult,
}, comps)

