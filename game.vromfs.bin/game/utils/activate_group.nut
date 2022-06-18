import "%dngscripts/ecs.nut" as ecs

let {EventEntityActivate} = require("dasevents")

let findGroupQuery = ecs.SqQuery("findGroupQuery", {comps_ro = [["groupName", ecs.TYPE_STRING]]})

let function activateGroup(group_name) {
  let function sendEvent(eid, comp) {
    if (comp.groupName == group_name)
     ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=true}))
  }

  findGroupQuery.perform(sendEvent)
}

return activateGroup

