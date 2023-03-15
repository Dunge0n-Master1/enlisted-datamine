import "%dngscripts/ecs.nut" as ecs
let {logerr} = require("dagor.debug")
let {setTimeout} = require("dagor.workcycle")
let console = require("console")

let random = require("dagor.random")
let {exit_game} = require("app")
let {EventLevelLoaded} = require("gameevents")
let {EventForceCapture, EventTeamWon} = require("dasevents")
let {getMissionType} = require("%enlSqGlob/missionType.nut")

let capzoneQuery = ecs.SqQuery("capzoneQuery", {comps_ro=["active", "transform", "capzone__capTeam"], comps_rq=["capzone"]})

let teamWon = random.rnd_int(1, 2)

let function exit_game_logger() {
  logerr("Forced exit. Run test local.")
  exit_game()
}

let function team_won() {
  ecs.g_entity_mgr.broadcastEvent(EventTeamWon({team=teamWon}))
}

let function force_capture(){
  capzoneQuery.perform(function(eid, _comps) {
    ecs.g_entity_mgr.sendEvent(eid, EventForceCapture({team=teamWon}, eid))
  })
  setTimeout(30, exit_game_logger)
}

let function force_escort() {
  let capzonesPos = []
  capzoneQuery.perform(function(_eid, comps) {
    if (comps.active){
      capzonesPos.append(comps.transform[3])
    }
  })
  console.command($"phys.teleport {capzonesPos[capzonesPos.len()-1].x}, {capzonesPos[capzonesPos.len()-1].y}, {capzonesPos[capzonesPos.len()-1].z}")
  setTimeout(5, force_escort)
}

let function onLevelLoaded(_eid, _comp) {
  console.command("app.timeSpeed 20")

  local missionType = getMissionType()
  if (missionType == "invasion"){
    force_capture()
    setTimeout(5, team_won)
  }
  else if (missionType == "domination"){
    force_capture()
    console.command($"team.set_score 10, {(teamWon == 1) ? 2: 1}")
  }
  else if (missionType == "assault"){
    force_capture()
    if(teamWon==2)
      setTimeout(5, team_won)
  }
  else if (missionType == "destruction"){
    force_capture()
  }
  else if (missionType == "escort"){
    setTimeout(5, force_escort)
  }
  else if (missionType == "confrontation"){
    setTimeout(5, force_capture)
  }
  else {
    setTimeout(10, exit_game)
  }

}

ecs.register_es("quit_after_mission_completion_es", {
  [EventLevelLoaded] = onLevelLoaded,
})