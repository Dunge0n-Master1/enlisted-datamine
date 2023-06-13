import "%dngscripts/ecs.nut" as ecs

let {EventOnDisconnectedFromServer} = require("gameevents")
let {CmdReplayRewindSaveState, CmdReplayRewindLoadState} = require("dasevents")
let {switch_to_menu_scene} = require("app")
let {nestWatched} = require("%dngscripts/globalState.nut")

let replaySavedState = nestWatched("replaySavedState", {})

ecs.register_es("replay_rewind_state_save_es", {
  [[CmdReplayRewindSaveState]] = @(evt, _eid, _comp) replaySavedState(evt.state.getAll())
}, {}, {tags="playingReplay"})

ecs.register_es("replay_rewind_state_load_es", {
  [["onInit"]] = function(...) {
    if (replaySavedState.value.len() == 0)
      return
    let state = ecs.CompObject()
    foreach (key, val in replaySavedState.value)
      state[key] <- val
    ecs.g_entity_mgr.broadcastEvent(CmdReplayRewindLoadState({ state }))
    replaySavedState({})
  }
}, { comps_rq=["replay__startAt"] }, { tags="playingReplay" })


ecs.register_es("replay_finalize_session_es", {
  [EventOnDisconnectedFromServer] = @(...) switch_to_menu_scene(),
}, {}, {tags = "playingReplay", before="ui_disconnected_from_server_es"})
