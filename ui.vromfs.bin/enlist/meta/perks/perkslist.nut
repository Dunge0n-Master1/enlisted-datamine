from "%enlSqGlob/ui_library.nut" import *

let serverConfigs = require("%enlist/meta/configs.nut")

let perkList = persist("list", @() {})
serverConfigs.configs.subscribe(
  function(v) {
    let list = v?.perks?.list
    if (list == null)
      return

    perkList.clear()
    foreach (id, perk in list) {
      perk.locId <- perk?.locId ?? id
      perkList[id] <- perk
    }
})

return perkList