from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { medals } = require("%enlist/meta/profile.nut")
let { add_medal } = require("%enlist/meta/clientApi.nut")
let { medalsPresentation } = require("medalsPresentation.nut")


let medalsCfg = Computed(function() {
  let receivedById = {}
  foreach (medal in medals.value) {
    let { id, cTime } = medal
    receivedById[id] <- (receivedById?[id] ?? []).append(cTime)
  }

  return (configs.value?.medalsCfg ?? {})
    .map(@(medalCfg, id) medalCfg
      .__merge({ id, received = receivedById?[id] ?? [] }, medalsPresentation?[id] ?? {})
    )
})

let medalsByCampaign = Computed(function() {
  let res = {}
  foreach (medal in medalsCfg.value) {
    let { campaign } = medal
    if (campaign not in res)
      res[campaign] <- []
    res[campaign].append(medal)
  }

  return res.map(@(campaignMedals) campaignMedals
    .sort(@(a, b) (b?.weight ?? 0) <=> (a?.weight ?? 0) || a.id <=> b.id))
})

console_register_command(@(id) add_medal(id), "meta.addMedal")


return {
  medalsCfg
  medalsByCampaign
}
