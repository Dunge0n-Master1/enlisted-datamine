import "%dngscripts/ecs.nut" as ecs

let {EventEntityActivate} = require("dasevents")

let deactivateGroupQuery = ecs.SqQuery("deactivateGroupQuery", {comps_ro = [["groupName", ecs.TYPE_STRING]]})

let function deactivateGroup(group_name){
  let function sendEvent(eid, comp) {
    if (comp.groupName == group_name)
      ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=false}))
  }
  deactivateGroupQuery.perform(sendEvent)
}

return deactivateGroup

