from "%enlSqGlob/ui_library.nut" import *

let {deathsLog} = require("%ui/hud/state/kill_log_es.nut")
let {textarea} = require("%ui/components/textarea.nut")

let textStyle = freeze({
  size = [sw(40), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  transform = {pivot = [0.5, 0]}
  animations = [
    { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.83, playFadeOut=true, easing=OutCubic }
  ]
})

let ffKillMsg = textarea(loc("friendly_fire_kill","You was killed by friendly fire"), textStyle)
let enemyKillMsg = textarea(loc("enemy_fire_kill", "You was killed by enemy"), textStyle)
let function deathMessage(item) {
  let {name=null, inMyTeam=false} = item
  local children
  if (name == null)
    children = inMyTeam ? ffKillMsg : enemyKillMsg
  else {
    children = inMyTeam
      ? textarea(loc("your_teammate_killer", "You was occasionally killed by teammate: {name}", {name=loc(name)}), textStyle)
      : textarea(loc("your_enemy_killer", "Your killer: {name}", {name=loc(name)}), textStyle)
  }
  return {
    key = item
    children
  }
}

let function playerDeaths(){
  let children = deathsLog.events.value.map(deathMessage)
  return {
    flow = FLOW_VERTICAL
    watch = deathsLog.events
    children
    gap = hdpx(2)
  }
}

return {
  playerDeaths
}