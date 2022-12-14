import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerEid, localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {CmdSetMarkEnemy} = require("dasevents")

let showTeamEnemyHint = Watched(true)
let teamHintsQuery = ecs.SqQuery("teamEmenyHintQuery", {
  comps_ro =[["team__id", ecs.TYPE_INT], ["team__showEnemyHint", ecs.TYPE_BOOL, true]]})

localPlayerEid.subscribe(function(v) {
  if ( v != ecs.INVALID_ENTITY_ID ) {
    teamHintsQuery.perform(function (_eid, comp) {
        showTeamEnemyHint(comp["team__showEnemyHint"])
      },
      $"eq(team__id, {localPlayerTeam.value})"
    )
  }
})

let function setEnemyHint(_event){
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdSetMarkEnemy())
}
let teamEnemyHint = { eventHandlers = {["HUD.SetMark"] = setEnemyHint}}

let function localTeamEnemyHint(){
  return {
    watch = [showTeamEnemyHint]
    children = showTeamEnemyHint.value ? teamEnemyHint : null
    size = SIZE_TO_CONTENT
  }
}
return {
  localTeamEnemyHint
  showTeamEnemyHint
  setEnemyHint
}