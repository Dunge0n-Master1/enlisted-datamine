import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
let { logerr } = require("dagor.debug")
let {TEAM_UNASSIGNED} = require("team")
let { loadJson } = require("%sqstd/json.nut")
let {floor} = require("math")
let {INVALID_CONNECTION_ID, get_sync_time} = require("net")
let Rand = require("%sqstd/rand.nut")
let {generatedNames, botSuffix} = require("%scripts/game/utils/generated_names.nut")
let pickword = require("%sqstd/random_pick.nut")
let {date} = require("datetime")
let {INVALID_USER_ID} = require("matching.errors")
let {CmdSpawnSquad, EventTeamMemberJoined} = require("dasevents")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let { applyModsToArmies } = require("%scripts/game/utils/profile_init.nut")

let botsProfile = persist("bots_profile", @() {armies = require("%enlSqGlob/data/bots_profile.nut")})
let customProfile = persist("custom_bots_profile", @() {armies = null})

let function onInit(_evt, spawn_eid, comp) {
  botsProfile.armies = applyModsToArmies(botsProfile.armies)
  ecs.clear_timer({eid=spawn_eid, id="bot_squad_spawner"})
  ecs.set_timer({eid=spawn_eid, id="bot_squad_spawner", interval=comp.spawnPeriod, repeat=true})
}

local usedNames = {}

local function genName(seed) {
  let allow_cache = true
  local name
  do {
    name = $"{pickword(generatedNames, seed++, allow_cache)}{botSuffix}"
  } while (name in usedNames)
  usedNames[name] <- true
  return name
}

let availableTeamsQuery = ecs.SqQuery("availableTeamsQuery", {comps_ro=[["team__id", ecs.TYPE_INT]]})
let playerQuery = ecs.SqQuery("playerQuery", {
  comps_ro=[
    ["team", ecs.TYPE_INT],
    ["disconnected", ecs.TYPE_BOOL],
    ["disconnectedAtTime", ecs.TYPE_FLOAT],
    ["possessed", ecs.TYPE_EID]
  ],
  comps_rq=["countAsAlive", "player"]
})

let havePlayersQuery = ecs.SqQuery("havePlayersQuery", {
  comps_ro=[["possessed", ecs.TYPE_EID]],
  comps_rq=["countAsAlive", "player"]
})
let botPlayerQuery = ecs.SqQuery("botPlayerQuery", {comps_ro=[["team", ecs.TYPE_INT]], comps_rq=["countAsAlive", "player", "playerIsBot"]})

let function onTimer(_evt, _eid, comp) {
  if (comp.numBotSquadsSpawned < 1) { // if we haven't spawned bots yet
    let havePlayers = havePlayersQuery.perform( function(_eid, comp) { if (comp.possessed) return true })
    let allowSpawnBeforePlayer = comp["bot_spawner__allowSpawnBeforePlayer"]
    if (!havePlayers && !allowSpawnBeforePlayer) // check if we have any players, otherwise - do not try to spawn bots
      return
    usedNames = {}
  }

  let playersByTeam = {}

  availableTeamsQuery(function(eid, comp) {
    playersByTeam[comp["team__id"]] <- { eid = eid, botsCount = 0, totalCount = 0 }
  })

  botPlayerQuery(function(_eid, comp) {
    if (playersByTeam?[comp.team] != null)
      playersByTeam[comp.team].botsCount++
  })

  playerQuery(function(_eid, comp) {
    if (playersByTeam?[comp.team] != null && (!comp.disconnected || comp.disconnectedAtTime <= 0 || get_sync_time() - comp.disconnectedAtTime <= 60.0))
      playersByTeam[comp.team].totalCount++
  })

  local addPlayerToTeam = TEAM_UNASSIGNED

  let maxPlayersCountPerTeam = floor(comp.targetPopulation / 2).tointeger()
  local minTeamPlayersCount = -1
  foreach (teamId, team in playersByTeam) {
    if (minTeamPlayersCount < 0 || team.totalCount < minTeamPlayersCount) {
      minTeamPlayersCount = team.totalCount
      addPlayerToTeam = teamId
    }

    let shouldReduceBotsCount = team.totalCount > maxPlayersCountPerTeam && team.botsCount > 0
    ecs.obsolete_dbg_set_comp_val(team.eid, "team__shouldReduceBotsCount", shouldReduceBotsCount)
  }

  if (minTeamPlayersCount >= maxPlayersCountPerTeam || addPlayerToTeam == TEAM_UNASSIGNED)
    return;

  let team = addPlayerToTeam

  let time = date()
  let rand = Rand(time.min * 60 + time.sec)

  let teamEid = get_team_eid(team)
  let teamArmies = ecs.obsolete_dbg_get_comp_val(teamEid, "team__armies")?.getAll() ?? []
  let armies = customProfile.armies ?? botsProfile.armies
  let armyId = teamArmies.findvalue(@(a) a in armies)
  if (armyId == null) {
    logerr($"[BOT_SPAWNER] Unable to spawn bots because of not found army in botArmies. team armies: {", ".join(teamArmies)}")
    return
  }
  let army = armies[armyId]
  let squadsCount = army.squads.len()
  log($"[BOT_SPAWNER] Spawn bot for team {team} army {armyId}. (team armies = [{", ".join(teamArmies)}], squadsCount = {squadsCount})")

  // create player
  let playerComps = {
    "connid" : [INVALID_CONNECTION_ID, ecs.TYPE_INT],
    "canBeLocal" : [false, ecs.TYPE_BOOL],
    "userid" : [INVALID_USER_ID, ecs.TYPE_UINT64],
    "isFirstSpawn" : [false, ecs.TYPE_BOOL],
    "army" : armyId,
    "armies" : armies,
    "isArmiesReceived" : [true, ecs.TYPE_BOOL],
    "armiesReceivedTime" : get_sync_time(),
    "team": [team, ecs.TYPE_INT]
    "armiesReceivedTeam": [team, ecs.TYPE_INT],
    "squads__count": [squadsCount, ecs.TYPE_INT],
    "shouldValidateSpawnRules" : [false, ecs.TYPE_BOOL],
  }

  ecs.g_entity_mgr.createEntity("enlisted_bot_player", playerComps,
      function(plr_eid) {
        ecs.obsolete_dbg_set_comp_val(plr_eid, "name", genName(plr_eid + time.sec + time.min * 60))
        ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=plr_eid, team=team}));
        let squadId = rand.rint(0, squadsCount-1)
        ecs.g_entity_mgr.sendEvent(plr_eid,
          CmdSpawnSquad({
            team
            squadId
            possessed = ecs.INVALID_ENTITY_ID
            memberId = 0
            respawnGroupId = -1
          })
        )
      })

  comp.numBotSquadsSpawned++
}

ecs.register_es(
  "bot_squad_spawner_es",
  {
    onInit = onInit,
    Timer = onTimer
  },
  {
    comps_rw = [["numBotSquadsSpawned", ecs.TYPE_INT]],
    comps_ro = [
      ["targetPopulation", ecs.TYPE_INT],
      ["spawnPeriod", ecs.TYPE_FLOAT],
      ["bot_spawner__allowSpawnBeforePlayer", ecs.TYPE_BOOL, false]
    ]
  },
  {tags="server"}
)

ecs.register_es(
  "bots_custom_profile_init",
  {
    onInit = @(_eid, comp) customProfile.armies <- applyModsToArmies(loadJson(comp["customBotProfile"]))
  },
  { comps_ro = [["customBotProfile", ecs.TYPE_STRING]] },
  {tags="server"}
)
