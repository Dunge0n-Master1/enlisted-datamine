from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")

let perkList = Computed(function() {
  let list = configs.value?.perks.list
  let res = {}
  if (list == null)
    return res

  foreach (id, p in list) {
    let perk = clone p
    perk.locId <- perk?.locId ?? id
    res[id] <- perk
  }
  return res
})

return perkList