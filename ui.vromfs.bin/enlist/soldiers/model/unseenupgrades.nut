from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { itemUpgrades, getModifyConfig } = require("config/itemsModifyConfig.nut")
let { ceil } = require("%sqstd/math.nut")
let { allItemTemplates } = require("all_items_templates.nut")
let { curArmiesList, itemsByArmies, soldiersByArmies
} = require("%enlist/meta/profile.nut")
let { itemCountByArmy, curArmy, chosenSquadsByArmy, armyItemCountByTpl } = require("state.nut")
let { upgradeCostMultByArmy } = require("%enlist/researches/researchesSummary.nut")
let { getLinkedSquadGuid, getItemIndex } = require("%enlSqGlob/ui/metalink.nut")


const SEEN_ID = "seen/upgrades"
const USED_ID = "used/upgrades"

let seen = Computed(@() settings.value?[SEEN_ID])
let isUpgradeUsed = Computed(@() settings.value?[USED_ID])

let ignoreSlots = { secondary = true }

let function markUpgradesUsed(isUsed = true) {
  settings.mutate(@(set) set[USED_ID] <- isUsed)
}

let function markSeenUpgrades(armyId, iGuidsList) {
  if (armyId == null)
    return

  let seenUpdates = seen.value?[armyId] ?? {}
  let filtered = iGuidsList.filter(@(name) name not in seenUpdates)
  if (filtered.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let updatesSaved = clone (saved?[armyId] ?? {})
    filtered.each(@(name) updatesSaved[name] <- true)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

let function markUnseenUpgrades(armyId, iGuidsList) {
  let seenUpdates = seen.value?[armyId] ?? {}
  let filtered = iGuidsList.filter(@(name) name in seenUpdates)
  if (filtered.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let updatesSaved = (saved?[armyId] ?? {})
      .filter(@(_, name) filtered.findindex(@(v) v == name) == null)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

let function updateSeen(armyId, availableUpgrades) {
  let seenUpdates = seen.value?[armyId] ?? {}
  if (seenUpdates.len() == 0)
    return

  let filtered = seenUpdates.filter(@(name) name not in availableUpgrades).keys()
  if (filtered.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let updatesSaved = (saved?[armyId] ?? {})
      .filter(@(_, name) filtered.findindex(@(v) v == name) == null)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

let function getEquipInfoByItem(item, curSoldiers) {
  let links = item?.links ?? {}
  if (links.len() <= 1)
    return null

  foreach (link, linkType in links)
    if (link in curSoldiers && (linkType not in ignoreSlots)) {
      let soldier = curSoldiers[link]
      return {
        soldier = link
        index = getItemIndex(soldier) ?? 0
        squad = getLinkedSquadGuid(soldier)
      }
    }

  return null
}

let availableUpgradesByArmy = Computed(function() {
  let itemsCount = itemCountByArmy.value
  let allTemplates = allItemTemplates.value
  let upgradeCostMult = upgradeCostMultByArmy.value

  let res = {}
  foreach (armyId in curArmiesList.value) {
    res[armyId] <- {}
    let armyItemsCount = itemsCount?[armyId] ?? {}
    let armyUpgradeCostMult = upgradeCostMult?[armyId]
    let armyTemplates = allTemplates?[armyId]
    foreach (tpl, _ in armyItemsCount) {
      let itemTemplate = armyTemplates?[tpl]
      if ((itemTemplate?.upgradeitem ?? "") == "")
        continue

      let { tier = 0, itemtype = "" } = itemTemplate
      let upgrades = getModifyConfig(itemUpgrades.value, tier, itemtype)
      if (upgrades == null)
        continue

      let upgradeMult = armyUpgradeCostMult?[tpl] ?? 1.0
      foreach (priceTpl, price in upgrades) {
        let ordersAvail = armyItemCountByTpl.value?[priceTpl] ?? 0
        local { count, isFixedPrice = false } = price
        if (!isFixedPrice)
          count = ceil(count * upgradeMult).tointeger()
        if (count > 0 && count <= ordersAvail) {
          res[armyId][tpl] <- true
          break
        }
      }
    }
  }
  return res
})

let availableUpgradesEquipsByArmy = Computed(function() {
  let armiesItems = itemsByArmies.value
  let armiesSoldiers = soldiersByArmies.value
  let armiesSquads = chosenSquadsByArmy.value
  let upgradesByArmy = availableUpgradesByArmy.value

  let res = {}
  foreach (armyId in curArmiesList.value) {
    let armyRes = {}
    let squadsIndexes = {}
    foreach (idx, squad in armiesSquads?[armyId] ?? [])
      squadsIndexes[squad.guid] <- idx

    let armyUpgrades = upgradesByArmy?[armyId] ?? {}
    let armyItems = armiesItems?[armyId] ?? {}
    let armySoldiers = armiesSoldiers?[armyId] ?? {}
    foreach (item in armyItems) {
      let tpl = item.basetpl
      if (tpl not in armyUpgrades)
        continue

      let equipData = getEquipInfoByItem(item, armySoldiers)
      if (equipData == null)
        continue

      if (tpl not in armyRes)
        armyRes[tpl] <- []

      armyRes[tpl].append(equipData.__update({
        priority = (squadsIndexes?[equipData.squad] ?? 1000) * 1000 + equipData.index
      }))
    }

    res[armyId] <- armyRes.map(function(tplData) {
      local bestPriority
      local bestIdx
      foreach (idx, itemData in tplData)
        if (bestPriority == null || itemData.priority < bestPriority) {
          bestPriority = itemData.priority
          bestIdx = idx
        }
      return tplData[bestIdx]
    })
  }
  return res
})

let unseenAvailableUpgradesByArmy = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let res = {}
  foreach (armyId in curArmiesList.value) {
    let seenData = seen.value?[armyId] ?? {}
    res[armyId] <- (availableUpgradesEquipsByArmy.value?[armyId] ?? {})
      .filter(@(_, tpl) tpl not in seenData)
  }
  return res
})

let curUnseenAvailableUpgrades = Computed(@()
  unseenAvailableUpgradesByArmy.value?[curArmy.value] ?? {})

let curUnseenUpgradesBySoldier = Computed(function() {
  let res = {}
  foreach (availUpgrade in curUnseenAvailableUpgrades.value) {
    let { soldier = null } = availUpgrade
    if (soldier != null)
      res[soldier] <- (res?[soldier] ?? 0) + 1
  }
  return res
})

let curUnseenUpgradesBySquad = Computed(function() {
  let res = {}
  foreach (availUpgrade in curUnseenAvailableUpgrades.value) {
    let { squad = null } = availUpgrade
    if (squad != null)
      res[squad] <- (res?[squad] ?? 0) + 1
  }
  return res
})

let unseenUpgradesByArmy = Computed(function() {
  let res = {}
  foreach (armyId, armyUpgradesData in unseenAvailableUpgradesByArmy.value) {
    res[armyId] <- {}
    foreach (upgradeData in armyUpgradesData) {
      let { soldier = null } = upgradeData
      if (soldier not in res[armyId])
        res[armyId][soldier] <- true
    }
  }
  return res
})

availableUpgradesEquipsByArmy.subscribe(function(v) {
  foreach (armyId, data in v)
    updateSeen(armyId, data)
})

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
    if (USED_ID in s)
      delete s[USED_ID]
  })
}, "meta.resetSeenUpdates")

return {
  isUpgradeUsed
  markUpgradesUsed
  markSeenUpgrades
  markUnseenUpgrades
  curUnseenAvailableUpgrades
  curUnseenUpgradesBySoldier
  curUnseenUpgradesBySquad
  unseenUpgradesByArmy
}
