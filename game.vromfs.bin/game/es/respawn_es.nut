import "%dngscripts/ecs.nut" as ecs

let console = require("console")
let logHR = require("%sqstd/log.nut")().with_prefix("[HERO_RESPAWN]")
let { isSandboxContext, getSandboxConfigValue } = require("sandbox_read_config.nut")

let function onRequestRespawn(evt, eid, comp) {
  let respRequestedSquadId  = evt.data?.squadId ?? 0
  let respRequestedMemberId = evt.data?.memberId ?? 0
  let respawnGroupId        = evt.data?.spawnGroup ?? -1
  logHR($"onRequestRespawn: {eid}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  comp["respawner__respRequested"] = true
  comp["respawner__respRequestedSquadId"]  = respRequestedSquadId
  comp["respawner__respRequestedMemberId"] = respRequestedMemberId
  comp["respawner__respawnGroupId"]        = respawnGroupId
}

let function onCancelRequestRespawn(evt, eid, comp) {
  let respRequestedSquadId  = evt.data?.squadId ?? 0
  let respRequestedMemberId = evt.data?.memberId ?? 0
  let respawnGroupId        = evt.data?.spawnGroup ?? -1
  logHR($"onCancelRequestRespawn: {eid}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  comp["respawner__respRequested"] = false
  comp["respawner__respRequestedSquadId"]  = respRequestedSquadId
  comp["respawner__respRequestedMemberId"] = respRequestedMemberId
  comp["respawner__respawnGroupId"]        = respawnGroupId
}

ecs.register_es("respawn_req_es",
  {
    [ecs.sqEvents.CmdRequestRespawn] = onRequestRespawn,
    [ecs.sqEvents.CmdCancelRequestRespawn] = onCancelRequestRespawn
  },
  {
    comps_rw = [
      ["respawner__respawnGroupId", ecs.TYPE_INT],
      ["respawner__respRequested", ecs.TYPE_BOOL],
      ["respawner__respRequestedSquadId", ecs.TYPE_INT],
      ["respawner__respRequestedMemberId", ecs.TYPE_INT],
    ]
  },
  {tags="server"}
)

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