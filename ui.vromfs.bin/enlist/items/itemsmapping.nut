from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { rewardsPresentation, mkReward } = require("itemsPresentation.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

// FIXME: rewardsPresentation shoulb be used only here
// in other places you need to use rewardsItemMapping
let rewardsItemMapping = Computed(function() {
  let mapping = configs.value?.addItemMapping
  let res = clone rewardsPresentation
  if (mapping == null)
    return res

  let { nameorig = "" } = userInfo.value
  foreach (key, reward in mapping)
    res[key] <- reward.__merge(res?[key] ?? mkReward(reward, nameorig) ?? {})
  return res
})

return rewardsItemMapping
