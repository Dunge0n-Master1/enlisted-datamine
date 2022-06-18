import "%dngscripts/ecs.nut" as ecs
let {userstatsAdd} = require("%scripts/game/utils/userstats.nut")
let {EventOnPlayerLooted} = require("lootevents")

let function onPlayerLooted(evt, _eid, comp) {
  let evt_type = evt[0]
  let evt_region = evt[1]
  let awardParams = {
    userid = comp.userid,
    appId = comp.appId,
    mode = evt_region
  }
  if (evt_type != "item") // item is our default
    userstatsAdd(comp.userstats, comp.userstats_mode, "looted_{0}".subst(evt_type), awardParams)
  userstatsAdd(comp.userstats, comp.userstats_mode, "looted_item", awardParams)
}
ecs.register_es("playerstats_es", {
  [EventOnPlayerLooted] = onPlayerLooted,
}, {
  comps_rw = [ ["userstats", ecs.TYPE_OBJECT], ["userstats_mode", ecs.TYPE_OBJECT] ]
  comps_ro = [ ["userid", ecs.TYPE_UINT64], ["appId", ecs.TYPE_INT] ]
})

