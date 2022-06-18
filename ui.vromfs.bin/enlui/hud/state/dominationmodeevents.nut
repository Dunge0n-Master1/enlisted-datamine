from "%enlSqGlob/ui_library.nut" import *

let { whichTeamAttack } = require("%ui/hud/state/capZones.nut")
let { myScore, myScoreBleed, myScoreBleedFast } = require("%ui/hud/state/team_scores.nut")
let {playerEvents} = require("%ui/hud/state/eventlog.nut")
let {sound_play} = require("sound")

let isDominationMode = keepref(Computed(@() whichTeamAttack.value < 0))

let defEvent = {text=loc("The enemy's almost won!"), myTeamScores=false}
let defSound = "vo/ui/enlisted/narrator/loosing_scores_ally_domination"

let events = {
  showFailWarning = {
    watch = Computed(@() isDominationMode.value && (myScore.value < 0.2) && (myScoreBleed.value || myScoreBleedFast.value))
  }
  showFailFastWarning = {
    watch = Computed(@() isDominationMode.value && (myScore.value < 0.1) && (myScoreBleed.value || myScoreBleedFast.value))
  }
  showLowScore = {
    watch = Computed(@() isDominationMode.value && (myScore.value < 0.05))
  }
}
events.each(function(e){
  let {event=defEvent, sound = defSound, watch} = e
  keepref(watch)
  watch.subscribe(function(val) {
    if (val) {
      sound_play(sound)
      playerEvents.pushEvent(event)
    }
  })
})

