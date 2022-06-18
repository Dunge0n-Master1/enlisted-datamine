import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let rand = require("%sqstd/rand.nut")
let findNextSpectatorHumanTargetQuery = ecs.SqQuery("findNextSpectatorTargetQuery", {comps_rq=["human"], comps_ro=[["isAlive"], ["countAsAlive"]]}, "and(isAlive,countAsAlive)")
let findNextSpectatorTargetQuery = ecs.SqQuery("findNextSpectatorTargetQuery", {comps_rq=["transform", "camera__lookDir", "camera__look_at"]})

console_register_command(function(){
  let humans = ecs.query_map(findNextSpectatorHumanTargetQuery,@(eid, _comp) eid)
  console_command("camera.spectate {0}".subst(rand.chooseRandom(humans)))
},"spectate.randomHuman")

console_register_command(function(){
  let ents = ecs.query_map(findNextSpectatorTargetQuery,@(eid, _comp) eid)
  console_command("camera.spectate {0}".subst(rand.chooseRandom(ents)))
},"spectate.randomEntity")

local lastSpectated = 0
let function switchSpectate(delta, query){
  let ents = ecs.query_map(query, @(eid, _comp) eid).sort()
  if (ents.len()==0)
    return
  local lastSpectatedIdx = ents.indexof(lastSpectated) ?? 0
  lastSpectatedIdx = lastSpectatedIdx + delta
  if (lastSpectatedIdx > ents.len()-1)
    lastSpectatedIdx = 0
  if (lastSpectatedIdx < 0)
    lastSpectatedIdx = ents.len()-1
  lastSpectated = ents[lastSpectatedIdx]
  console_command("camera.spectate {0}".subst(ents[lastSpectatedIdx]))
}

console_register_command(@() switchSpectate(1, findNextSpectatorHumanTargetQuery),"spectate.nextHuman")
console_register_command(@() switchSpectate(-1, findNextSpectatorHumanTargetQuery),"spectate.prevHuman")
console_register_command(@() switchSpectate(1, findNextSpectatorTargetQuery),"spectate.next")
console_register_command(@() switchSpectate(-1, findNextSpectatorTargetQuery),"spectate.prev")
console_register_command(@() console_command("camera.spectate 0"), "spectate.stop")