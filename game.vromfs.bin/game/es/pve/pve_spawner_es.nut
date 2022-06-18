import "%dngscripts/ecs.nut" as ecs

let { spawnSquad } = require("%scripts/game/utils/squad_spawn.nut")

let pveMissionInfoQuery = ecs.SqQuery("pveMissionInfoQuery", {comps_ro=[["pve__botProfile", ecs.TYPE_OBJECT], ["pve__botTeam", ecs.TYPE_INT]]})

ecs.register_es("pve_init_es",
  {
    [["onInit"]] = function(_eid, comp) {
      let botProfileFile = comp["pve__botProfileFile"]
      comp["pve__botProfile"] = require($"%enlSqGlob/data/{botProfileFile}")
    }
  },
  {
    comps_ro = [["pve__botProfileFile", ecs.TYPE_STRING]],
    comps_rw = [["pve__botProfile", ecs.TYPE_OBJECT]]
  },
  { tags="server" }
)

ecs.register_es("pve_stage_active_es",
  {
    [["onInit", ecs.EventComponentsAppear]] = function(_eid, comp) {
      local enemyCount = 0
      let pveStageSpawner = comp["pve_stage__spawner"].getAll()
      let botExtraTemplate = comp["pve_stage__botExtraTemplate"]
      pveMissionInfoQuery(function(_eid, comp) {
        let botProfile = comp["pve__botProfile"].getAll()

        foreach (spawner in pveStageSpawner) {
          let squads = botProfile[spawner["armyId"]].squads
          let squad = squads.findvalue(@(val) val.squadId == spawner["squadId"]).squad

          enemyCount += spawner["count"]
          for (local i = 0; i < spawner["count"]; ++i) {
            spawnSquad({
              squad = squad
              team = comp["pve__botTeam"]
              playerEid = INVALID_ENTITY_ID
              memberId = squad.findindex(@(val) val.guid == spawner["soldierGuid"])
              addTemplatesOnSpawn = botExtraTemplate
            })
          }
        }
      })
      comp["pve_stage__enemyCount"] = enemyCount
    }
  },
  {
    comps_ro = [
      ["pve_stage__spawner", ecs.TYPE_ARRAY],
      ["pve_stage__botExtraTemplate", ecs.TYPE_STRING, null],
    ],
    comps_rw = [
      ["pve_stage__enemyCount", ecs.TYPE_INT]
    ],
    comps_rq = [["pve__active"]]
  },
  { tags="server" }
)