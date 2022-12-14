import "%dngscripts/ecs.nut" as ecs
let logImd = require("%enlSqGlob/library_logs.nut").with_prefix("[InitMatchingData] ")
let dagorsys = require("dagor.system")
let { get_matching_invite_data, set_matching_invite_data } = require("app")
let { EventLevelLoaded } = require("gameevents")
let { isSandboxContext, getSandboxConfigValue } = require("sandbox_read_config.nut")
let {INVALID_USER_ID} = require("matching.errors")

const TEAM_ALIES = 1
const TEAM_AXIS = 2


let modifyTeamQuery = ecs.SqQuery("modifyTeamQuery",
  { comps_rw = [["team__armies", ecs.TYPE_STRING_LIST]]
    comps_ro = [["team__id", ecs.TYPE_INT]]
  })

let function initMatchingData() {
  logImd("Init matching data")

  let modeInfo = get_matching_invite_data()?.mode_info
  local { teamArmies = "historical", campaigns = [], difficulty = "standard",
    botpop = null, botAutoSquad = null, botSpawnPeriod = null, mode = null,
    voteToKick = false, creatorId = INVALID_USER_ID, spawnMode = null
  } = modeInfo
  logImd($"modeInfo:{modeInfo != null}, mode:{mode}, difficulty:{difficulty}")

  try{
    botpop = botpop ?? dagorsys.get_arg_value_by_name("botpop")?.tointeger() ?? 0
  }
  catch(e){
    logImd(e)
    botpop = 0
  }

  if (isSandboxContext()) {
    difficulty = getSandboxConfigValue("difficulty", difficulty)
    mode       = getSandboxConfigValue("mode", mode)
    botpop     = getSandboxConfigValue("botpop", botpop)
    spawnMode  = getSandboxConfigValue("spawnMode", spawnMode)
  }

  if (botpop > 0) {
    logImd($"Playing with {botpop} bots")
    botAutoSquad = botAutoSquad ?? (dagorsys.get_arg_value_by_name("botAutoSquad") != null)
    botSpawnPeriod = botSpawnPeriod ?? dagorsys.get_arg_value_by_name("spawnPeriod")?.tofloat() ?? 1.0
    ecs.g_entity_mgr.createEntity("bots_squad_spawner", {
          "targetPopulation"  : [ botpop, ecs.TYPE_INT]
          "bots_ai_spawner__botAutoSquad"  : [ botAutoSquad, ecs.TYPE_BOOL]
          "spawnPeriod" : [ botSpawnPeriod, ecs.TYPE_FLOAT]
    })
  }

  if (voteToKick)
    ecs.g_entity_mgr.createEntity("vote_to_kick", {})

  if (campaigns.len() > 0) {
    let armiesByTeam = { [TEAM_ALIES] = "{0}_allies", [TEAM_AXIS] = "{0}_axis" }
      .map(@(ac) campaigns.map(@(c) ac.subst(c)))
    if (teamArmies != "historical") {
      armiesByTeam[TEAM_ALIES].extend(armiesByTeam[TEAM_AXIS])
      armiesByTeam[TEAM_AXIS] = armiesByTeam[TEAM_ALIES]
    }
    logImd("Team armies: ", armiesByTeam)

    local inited = 0
    modifyTeamQuery(function(_eid, comp) {
      let id = comp["team__id"]
      if (id not in armiesByTeam)
        return

      let list = ecs.CompStringList()
      armiesByTeam[id].each(@(armyId) list.append(armyId))
      comp["team__armies"] = list
      inited++
    })

    if (inited < armiesByTeam.len())
      logImd($"Inited only {inited} armies")
  }

  if (difficulty == "hardcore") {
    logImd($"Hardcore mode")
    let hardcoreModeTemplates = [
      "forceMinimalHud",
      "gamemodeFriendlyFire",
      "gamemodeCapzoneSmoke",
      "disableTeamkillWeaponDrops",
      "forceDisableHeadShotSound"
    ]
    foreach (tpl in hardcoreModeTemplates)
      ecs.g_entity_mgr.createEntity(tpl, {})
  }

  if (mode == "LONE_FIGHTERS") {
    logImd("LONE_FIGHTERS mode")
    ecs.g_entity_mgr.createEntity("add_spawn_on_squadmates+noBotsMode+gamemodeCapzoneSmoke", {})
  }

  if (spawnMode == "UNLIMITED_SPAWNS" ) {
    logImd("UNLIMITED_SPAWNS spawn mode")
    ecs.g_entity_mgr.createEntity("spawnMode_unlimitedSpawns", {})
  }
  if (spawnMode == "ONE_SPAWN_PER_UNIT") {
    logImd("ONE_SPAWN_PER_UNIT spawn mode")
    ecs.g_entity_mgr.createEntity("spawnMode_oneSpawnPerUnit", {})
  }

  if (typeof creatorId == "string")
    creatorId = creatorId.tointeger()

  ecs.g_entity_mgr.createEntity("custom_room_info", {
    "custom_room_info__owner": [ creatorId, ecs.TYPE_UINT64 ]
  })
}

ecs.register_es("init_matching_data_es",
  { [EventLevelLoaded] = @(_eid, _comp) initMatchingData() },
  {},
  { tags = "server" })

ecs.register_es("reset_client_matching_data_es",
  { [EventLevelLoaded] = @(_eid, _comp) set_matching_invite_data({}) },
  {},
  { tags = "gameClient", after="init_matching_data_es" })
