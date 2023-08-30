from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { CmdParatroopersPointDeleted, CmdPickParatroopersPoint, CmdTurnParatroopersCamera, CmdParatroopersSpawnConfirm, sendNetEvent } = require("dasevents")
let { selectedRespawnGroupId, showSquadSpawn, paratroopersPointSelectorOn, paratroopersOn, isParatroopersSquad } = require("%ui/hud/state/respawnState.nut")
let { get_sync_time } = require("net")
let { battleAreaScreenProjection, projectionOn } = require("%ui/hud/menus/battle_area_screen_projections.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")

let newPointSelectTimer = Watched(-1.)
let paratroopersPointExisted = Watched(false)

let showParatroopersPointProjection = Computed(@() !isReplay.value && showSquadSpawn.value && projectionOn.value)

let function paratroopers_turn(on){
  paratroopersOn(on)
  selectedRespawnGroupId.mutate(@(v) v["paratroopers"] <- on ? 0 : -1)
  newPointSelectTimer(on ? get_sync_time() + 0.3 : -1.)
  paratroopersPointExisted(on)
}

let function delete_paratroopers_icon() {
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdParatroopersPointDeleted())
  paratroopers_turn(false)
}

showSquadSpawn.subscribe(function(v){
  if (!v) {
    delete_paratroopers_icon()
    projectionOn(false)
  }
})

isParatroopersSquad.subscribe(@(v) sendNetEvent(localPlayerEid.value, CmdTurnParatroopersCamera({paratroopersCameraOn = v})))

paratroopersPointSelectorOn.subscribe(function(v) {
  if (v || showSquadSpawn.value)
    sendNetEvent(localPlayerEid.value, CmdTurnParatroopersCamera({paratroopersCameraOn = v}))
  if (!v)
    paratroopersOn(false)
  else
    paratroopers_turn(paratroopersPointExisted.value)
})

ecs.register_es("paratroopers_icon_created", {
  [CmdParatroopersSpawnConfirm] = function() {
    if (paratroopersPointSelectorOn.value)
      paratroopers_turn(true)
    }
  },
  { comps_rq = ["respawner"] }
)

let function pick_paratroopers_point(event){
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdPickParatroopersPoint({coordX = event.screenX, coordY = event.screenY}))
}

let function paratroopersPointSelectorPanel(){
  if (!showParatroopersPointProjection.value)
    return @(){ watch = showParatroopersPointProjection}
  return  @(){
    watch = showParatroopersPointProjection
    size = [sw(100), sh(100)]
    behavior = Behaviors.Button
    onClick = @(event) get_sync_time() < newPointSelectTimer.value ? null : pick_paratroopers_point(event)
    children = [battleAreaScreenProjection]
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true }
      { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.3, playFadeOut = true }
    ]
  }
}

let paratroopers_point_ctor = {
  ctor = paratroopersPointSelectorPanel
  watch = [showParatroopersPointProjection]
}

return {
  paratroopers_point_ctor,
  delete_paratroopers_icon,
  paratroopersPointExisted,
}
