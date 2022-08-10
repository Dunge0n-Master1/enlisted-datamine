import "%dngscripts/ecs.nut" as ecs
let {get_setting_by_blk_path} = require("settings")
let { TEAM_UNASSIGNED } = require("team")
let {floor} = require("math")
let {INVALID_CONNECTION_ID, get_sync_time} = require("net")
let Rand = require("%sqstd/rand.nut")
let {get_gen_bot_name, clear_used_bot_names} = require("%scripts/game/utils/bot_name.nut")
let {date} = require("datetime")
let {INVALID_USER_ID} = require("matching.errors")
let {find_safest_respawn_base_for_team} = require("%scripts/game/utils/respawn_base.nut")
let assign_team = require("%scripts/game/utils/team.nut")
let { apply_customization=@(_, __, c) c, get_game_character_template=@(___) null } = require_optional("playerCustomization")
let {EventTeamMemberJoined} = require("dasevents")
let { Point2 } = require("dagor.math")

let gameBotTemplate = get_setting_by_blk_path("botPlayerTemplateName") ?? "bot_player"

let function startTimer(spawn_eid, duration) {
  ecs.set_timer({eid=spawn_eid, id="bot_player_spawner", interval=duration, repeat=false})
}

let function restartTimer(_evt, spawn_eid, comp) {
  ecs.clear_timer({eid=spawn_eid, id="bot_player_spawner"})
  if (comp.spawnPeriodRange.x > 0 && comp.spawnPeriodRange.y > 0)
    comp.spawnPeriod = comp.spawnPeriodRange.x
  startTimer(spawn_eid, comp.spawnStartOffset + comp.spawnPeriod)
}

let availableTeamsQuery = ecs.SqQuery("availableTeamsQuery", {comps_ro=[["team__id", ecs.TYPE_INT]]})
let onTimerTeamQuery = ecs.SqQuery("onTimerTeamQuery", {comps_ro=[["team", ecs.TYPE_INT]],comps_rq=["countAsAlive"]})
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

let botsCountMultQuery = ecs.SqQuery("botsCountMultQuery", {comps_ro=[["session_shrinker__botsShrinkMult", ecs.TYPE_FLOAT]]})

let function setTeam(eid, team) {
  if (ecs.obsolete_dbg_get_comp_val(eid, "team", null) != null)
    ecs.obsolete_dbg_set_comp_val(eid, "team", team)
}

let function onTimer(_evt, eid, comp) {
  if (comp.numBotsSpawned < 1) { // if we haven't spawned bots yet
    let havePlayers = havePlayersQuery.perform( function(_eid, comp) { if (comp.possessed) return true })
    if (!havePlayers) { // check if we have any players, otherwise - do not try to spawn bots
      startTimer(eid, comp.spawnPeriod)
      return
    }
    clear_used_bot_names()
  }

  let botsCountMult = botsCountMultQuery.perform( function(_eid, comp) { return comp["session_shrinker__botsShrinkMult"] }) ?? 1.0

  local currentPopulation = 0
  let teamTable = {}
  let shouldCountTeams = comp.countTeams
  let playersByTeam = {}
  if (shouldCountTeams) {
    onTimerTeamQuery.perform(
        function(_eid, comp) {
          if (!(comp.team in teamTable)) {
            teamTable[comp.team] <- 1
            currentPopulation++
          }
        })
  }
  else if (comp.shouldBalanceTeams) {
    availableTeamsQuery.perform(function(eid, comp) {
      playersByTeam[comp["team__id"]] <- { eid = eid, botsCount = 0, totalCount = 0 }
    })
    botPlayerQuery.perform(function(_eid, comp) {
      if (playersByTeam?[comp.team] != null)
        playersByTeam[comp.team].botsCount++
    })
    playerQuery.perform(function(_eid, comp) {
      if (playersByTeam?[comp.team] != null && (!comp.disconnected || comp.disconnectedAtTime <= 0 || get_sync_time() - comp.disconnectedAtTime <= 60.0))
        playersByTeam[comp.team].totalCount++
    })
  }
  else {
    playerQuery.perform(
        function() {
          currentPopulation++
        })
  }
  if (!comp.createPlayer)
    currentPopulation += comp.numBotsSpawned

  local addPlayerToTeam = TEAM_UNASSIGNED
  if (comp.shouldBalanceTeams) {
    let maxPlayersCountPerTeam = floor((comp.targetPopulation * botsCountMult) / 2).tointeger()
    local minTeamPlayersCount = -1
    foreach (teamId, team in playersByTeam) {
      if (minTeamPlayersCount < 0 || team.totalCount < minTeamPlayersCount) {
        minTeamPlayersCount = team.totalCount
        addPlayerToTeam = teamId
      }

      let shouldReduceBotsCount = team.totalCount > maxPlayersCountPerTeam && team.botsCount > 0
      ecs.obsolete_dbg_set_comp_val(team.eid, "team.shouldReduceBotsCount", shouldReduceBotsCount)
    }

    if (minTeamPlayersCount >= maxPlayersCountPerTeam || addPlayerToTeam == TEAM_UNASSIGNED) {
      startTimer(eid, comp.spawnPeriod)
      return
    }
  }
  else if (currentPopulation >= (comp.targetPopulation * botsCountMult).tointeger() && comp.numBotsSpawned >= comp.minBotsToSpawn) {
    return
  }

  let time = date()
  let rand = Rand(time.min * 60 + time.sec)
  local gatherMeta
  gatherMeta = function(slot) {
    let meta = slot[rand.rint(0, slot.len() - 1)]
    if (typeof meta == "string")
      return [meta]
    else {
      let metaTable = meta.getAll()
      return [metaTable.meta].extend(gatherMeta(metaTable.items))
    }
  }

  let botsToSpawn = min(comp.targetPopulation * botsCountMult - currentPopulation, comp.spawnCount)
  for (local i = 0; i < botsToSpawn; ++i) {
    local team = addPlayerToTeam
    if ((comp.searchTeam || comp.assignTeam) && !comp.shouldBalanceTeams)
      team = assign_team()[0]
    let respBase = find_safest_respawn_base_for_team(team)
    if (respBase == INVALID_ENTITY_ID){
      // skip a bit, we probably will have new bases appearing soon
      startTimer(eid, comp.spawnPeriod)
      return
    }
    let transform = ecs.obsolete_dbg_get_comp_val(respBase, "transform")
    let comps = {
      "transform" : [transform, ecs.TYPE_MATRIX]
    }
    if (comp.assignTeam) {
      comps["team"] <- [team, ecs.TYPE_INT]
      setTeam(respBase, team)
    }
    else
      setTeam(respBase, comp.forceTeamForRespBase)
    let itemslist = []

    foreach (slot in comp.applyMeta) {
      if (rand.rfloat() < comp.metaChance)
        itemslist.extend(gatherMeta(slot))
    }
    local modComps = comps
    local templateToSpawn = comp.templateToSpawn
    if (itemslist.len() > 0) {
      let gameCharTemplate = get_game_character_template(itemslist)
      if (gameCharTemplate)
        templateToSpawn = $"{gameCharTemplate}+{templateToSpawn}"
      modComps = apply_customization(templateToSpawn, itemslist, comps)
    }
    let createPlayer = comp.createPlayer
    let assignTeam = comp.assignTeam

    ecs.g_entity_mgr.createEntity(templateToSpawn, modComps,
      function(ent_eid) {
        if (!createPlayer)
          return
        let playerComps = {
          "possessed" : [ent_eid, ecs.TYPE_EID],
          "connid" : [INVALID_CONNECTION_ID, ecs.TYPE_INT],
          "name" : [get_gen_bot_name(ent_eid + time.sec + time.min * 60), ecs.TYPE_STRING],
          "canBeLocal" : [false, ecs.TYPE_BOOL],
          "userid" : [INVALID_USER_ID, ecs.TYPE_UINT64],
          "player__metaItems" : [itemslist, ecs.TYPE_ARRAY],
          "possessedTemplate" : [templateToSpawn, ecs.TYPE_STRING]
        }
        if (assignTeam)
          playerComps["team"] <- [team, ecs.TYPE_INT]
        ecs.g_entity_mgr.createEntity(gameBotTemplate, playerComps,
          function(plr_eid) {
            ecs.obsolete_dbg_set_comp_val(ent_eid, "possessedByPlr", plr_eid)
            ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined({eid=plr_eid, team=team}))
          })
      })
  }

  comp.numBotsSpawned += botsToSpawn
  comp.spawnPeriod = comp.spawnPeriod - comp.spawnPeriodRangeStep * (comp.spawnPeriod - comp.spawnPeriodRange.y)
  startTimer(eid, comp.spawnPeriod)
}

ecs.register_es(
  "bot_player_spawner_es",
  {
    onInit = restartTimer,
    Timer = onTimer
  },
  {
    comps_rw = [["numBotsSpawned", ecs.TYPE_INT], ["spawnPeriod", ecs.TYPE_FLOAT]],
    comps_ro = [
      ["targetPopulation", ecs.TYPE_INT],
      ["minBotsToSpawn", ecs.TYPE_INT],
      ["templateToSpawn", ecs.TYPE_STRING],
      ["forceTeamForRespBase", ecs.TYPE_INT],
      ["assignTeam", ecs.TYPE_BOOL],
      ["createPlayer", ecs.TYPE_BOOL],
      ["applyMeta", ecs.TYPE_ARRAY],
      ["metaChance", ecs.TYPE_FLOAT],
      ["searchTeam", ecs.TYPE_BOOL, false],
      ["countTeams", ecs.TYPE_BOOL, true],
      ["shouldBalanceTeams", ecs.TYPE_BOOL, false],
      ["spawnPeriodRange", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
      ["spawnPeriodRangeStep", ecs.TYPE_FLOAT, 0],
      ["spawnCount", ecs.TYPE_INT, 1],
      ["spawnStartOffset", ecs.TYPE_FLOAT, 0]
    ]
  },
  {tags="server"}
)