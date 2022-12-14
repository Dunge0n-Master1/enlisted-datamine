import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {showBriefingOnSquadChange, briefingState, showBriefingForTime, showBriefingOnHeroChange} = require("briefingState.nut")
let {squadEid} = require("%ui/hud/state/hero_squad.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let {localPlayerTeamInfo} = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let showedBriefing = {
    //team = {briefing = true}
}
localPlayerTeam.subscribe(@(_) showedBriefing.clear())

let firstSpawnBriefingShown = mkWatched(persist, "firstSpawnBriefingShown", false)

controlledHeroEid.subscribe(function(value) {
  let curBriefing = localPlayerTeamInfo.value?["team__briefing"] ?? ""
  let curBriefingCommon = briefingState.value?["common"] ?? ""
  let function showBrief(){
    showedBriefing[curBriefing] <- 1
    showedBriefing[curBriefingCommon] <- 1
    showBriefingForTime(briefingState.value?.showtime ?? 10.0)
  }
  if (value == ecs.INVALID_ENTITY_ID)
    return
  if (!firstSpawnBriefingShown.value){
    firstSpawnBriefingShown(true)
    showBrief()
    return
  }
  if (!showBriefingOnHeroChange.value) {
    return
  }
  showBrief()
})

squadEid.subscribe(function(_){
  if (!showBriefingOnSquadChange.value)
    return
  showBriefingForTime(briefingState.value?.showtime ?? 10.0)
})
