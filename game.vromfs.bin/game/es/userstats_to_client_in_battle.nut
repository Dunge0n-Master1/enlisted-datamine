import "%dngscripts/ecs.nut" as ecs
let dedicated = require_optional("dedicated")
if (dedicated == null)
  return

let {playerUserstatComps, getPlayerCurrentUserstats} = require("%scripts/game/utils/getPlayerCurrentUserstats.nut")
let {get_matching_mode_info} = dedicated


ecs.register_es("userstats_to_client_in_battle_es", {
  function onChange(_, comp) {
    let modes = (clone (get_matching_mode_info()?.extraParams.userstatGroups ?? []))
      .append(comp.army)
    comp.userstatsInBattle = getPlayerCurrentUserstats(comp).__update({modes})
  }
},
{
  comps_rq = ["player"]
  comps_ro = [["team", ecs.TYPE_INT], ["army", ecs.TYPE_STRING]]
  comps_rw = [["userstatsInBattle", ecs.TYPE_OBJECT]]
  comps_track = playerUserstatComps
},
{tags = "server"}
)