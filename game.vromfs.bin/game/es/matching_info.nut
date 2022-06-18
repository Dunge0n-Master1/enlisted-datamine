import "%dngscripts/ecs.nut" as ecs
let {get_matching_mode_info=null} = require_optional("dedicated")
let {DBGLEVEL} = require("dagor.system")

if (get_matching_mode_info==null && DBGLEVEL<=0)
  return

let {EventLevelLoaded} = require("gameevents")


ecs.register_es("mathcing_info",
  {
    [[EventLevelLoaded, "onInit"]] = function(_eid, comp){
      let {teamsSlots=null} = get_matching_mode_info?()
      comp.teamsSlots.clear()
      if (teamsSlots!=null) {
        foreach (slot in teamsSlots)
          comp.teamsSlots.append(slot)
      }
    }
  },
  {comps_rw =[["teamsSlots", ecs.TYPE_INT_LIST]]},
  { tags="server" }
)