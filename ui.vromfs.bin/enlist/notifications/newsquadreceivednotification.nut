from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { squadUnlockInProgress } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { isUnlockSquadSceneVisible, openUnlockSquadScene
} = require("%enlist/soldiers/unlockSquadScene.nut")
let { squadsByArmies } = require("%enlist/meta/profile.nut")
let { openSquadsPromo, hasSquadsPromoOpened } = require("%enlist/soldiers/receivedSquadsWnd.nut")

const LAST_PROMO_ID = "seen/squads/promoTime"

let lastPromoTime = Computed(@() settings.value?[LAST_PROMO_ID] ?? {})
let squadsToPromo = Watched({})

let promoSquadsData = keepref(Computed(function() {
  if (squadUnlockInProgress.value != null)
    return {}

  return (squadsToPromo.value ?? {})
    .filter(@(squads) squads.len() > 0)
}))

let function updatePromoSquads(_) {
  if (!onlineSettingUpdated.value || !squadsCfgById.value.len())
    return

  let promoTime = lastPromoTime.value
  let promoTimeUpdate = {}
  let newSquadsToPromo = {} //armyId = { squad, ctime, armyId, squadCfg }
  foreach (armyId, list in squadsByArmies.value) {
    let lastTime = promoTime?[armyId] ?? 0

    local hasCoreSquads = false
    local isAllSquadsNew = true
    let promoSquads = []
    foreach (squad in list) {
      let ctime = squad.ctime.tointeger()
      let squadCfg = squadsCfgById.value?[armyId][squad.squadId]
      hasCoreSquads = hasCoreSquads || (squadCfg?.unlockCost ?? 0) <= 0
      if (ctime <= lastTime)
        isAllSquadsNew = false
      else if (squadCfg != null)
        promoSquads.append({ squad, ctime, armyId, squadCfg })
    }

    if (!isAllSquadsNew) //time was inited after army generation
      newSquadsToPromo[armyId] <- promoSquads
    else if (hasCoreSquads) //when not have core squads, army not inited yet
      promoTimeUpdate[armyId] <- promoSquads.reduce(@(res, s) max(res, s.ctime), 0)
  }

  if (promoTimeUpdate.len() > 0)
    settings.mutate(@(s) s[LAST_PROMO_ID] <- promoTime.__merge(promoTimeUpdate))

  squadsToPromo(newSquadsToPromo)
}

let updatePromoSquadsDebounced = debounce(updatePromoSquads, 0.1)
foreach (w in [onlineSettingUpdated, squadsCfgById, lastPromoTime, squadsByArmies])
  w.subscribe(updatePromoSquadsDebounced)
updatePromoSquadsDebounced(null)

let squadViewStyle = {
  unlockInfo = null
  isNewSquad = true
}

let function openPromoSquad(_) {
  let squadsByArmy = promoSquadsData.value
  if (squadsByArmy.len() == 0)
    return

  if (squadsByArmy.len() == 1) {
    let squadsList = squadsByArmy.values()[0]
    if (squadsList.len() == 1) {
      openUnlockSquadScene(squadsList[0].__merge(squadViewStyle), KWARG_NON_STRICT)
      return
    }
  }

  openSquadsPromo(squadsByArmy)
}

promoSquadsData.subscribe(debounce(openPromoSquad, 0.1))

let function markVisibleSquadPromoViewed(_) {
  if (!isUnlockSquadSceneVisible.value && !hasSquadsPromoOpened.value)
    return

  let seenData = {}
  foreach (armyId, squads in squadsToPromo.value)
    foreach (squad in squads)
      seenData[armyId] <- max(squad.ctime, seenData?[armyId] ?? 0)

  if (seenData.len() > 0)
    settings.mutate(@(s) s[LAST_PROMO_ID] <- lastPromoTime.value.__merge(seenData))
}

foreach (w in [isUnlockSquadSceneVisible, hasSquadsPromoOpened, squadsToPromo])
  w.subscribe(markVisibleSquadPromoViewed)
