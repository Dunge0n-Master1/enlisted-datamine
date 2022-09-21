import "%dngscripts/ecs.nut" as ecs

let console = require("console")
let { isSandboxContext, getSandboxConfigValue } = require("sandbox_read_config.nut")

let {get_all_arg_values_by_name} = require("dagor.system")

ecs.register_es("respawn_on_squad_from_console_es",
  {
    onChange = function(_evt, _eid, comp) {
      if (!comp.isFirstSpawn) { // respawner was inited
        let respawnerUserid = comp.userid?.tostring() ?? ""

        if (isSandboxContext()) {
          let squadId = getSandboxConfigValue("squad", "")
          if (squadId != "") {
            console.command($"squad.spawn {squadId} 0")
            return
          }
        }

        let ids = (get_all_arg_values_by_name("spawnSquadId") ?? []).map(@(s) s.split(","))
        foreach (spawnSquadId in ids) {
          let [userid,squadId] = spawnSquadId
          if (userid.tostring() == respawnerUserid) {
            console.command($"squad.spawn {squadId} {userid}")
            break
          }
        }
      }
    }
  },
  {
    comps_track=[["isFirstSpawn", ecs.TYPE_BOOL]]
    comps_ro = [["userid", ecs.TYPE_UINT64]]
  },
  {tags="server"})