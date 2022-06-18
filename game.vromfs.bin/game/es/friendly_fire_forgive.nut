import "%dngscripts/ecs.nut" as ecs
let { find_human_player_by_connid } = require("%dngscripts/common_queries.nut")
let { has_network, INVALID_CONNECTION_ID } = require("net")

let function onForgiveRequest(evt, forgiverEid, comp) {
  let offenderEid = evt.data?.eid ?? INVALID_ENTITY_ID
  if (!has_network() || forgiverEid != find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) || offenderEid == INVALID_ENTITY_ID)
    return
  let offenderKey = offenderEid.tostring()
  let statsToForgive = comp["friendly_fire__forgivableStats"]?[offenderKey]?.getAll() ?? []
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({list = statsToForgive}))
  comp["friendly_fire__forgivableStats"][offenderKey] <- []
}

ecs.register_es("friendly_fire_forgive",
  { [ecs.sqEvents.RequestForgiveFriendlyFire] = onForgiveRequest },
  {
    comps_rq = ["player"]
    comps_rw = [["friendly_fire__forgivableStats", ecs.TYPE_OBJECT]]
  },
  {tags="server"})
