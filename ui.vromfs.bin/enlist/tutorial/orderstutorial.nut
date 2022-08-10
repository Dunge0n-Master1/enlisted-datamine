from "%enlSqGlob/ui_library.nut" import *

let { viewArmyCurrency } = require("%enlist/shop/armyShopState.nut")
let { mkLogisticsPromoMsgbox } = require("%enlist/shop/currencyComp.nut")
let { needNewItemsWindow } = require("%enlist/soldiers/model/newItemsToShow.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let { setCurSection } = require("%enlist/mainMenu/sectionsState.nut")
let { settings, onlineSettingUpdated
} = require("%enlist/options/onlineSettings.nut")
let canDisplayOffers = require("%enlist/canDisplayOffers.nut")


const SEEN_ID = "seen/orderTutorials"

let seenData = Computed(@() onlineSettingUpdated.value && settings.value?[SEEN_ID])

let getTutorialType = @(orderId) getCurrencyPresentation(orderId).group

let canRunTutorial = mkWatched(persist, "canRunTutorial", false)
needNewItemsWindow.subscribe(function(val) {
  if (val)
    canRunTutorial(true)
})

let visibleTutorialId = keepref(Computed(function() {
  if (!canDisplayOffers.value || needNewItemsWindow.value || !canRunTutorial.value)
    return null

  let seen = seenData.value
  let curCurrency = viewArmyCurrency.value
  foreach (currId, _ in curCurrency) {
    let tutorialType = getTutorialType(currId)
    if ((tutorialType?.hasTutorial ?? false) && tutorialType.id not in seen)
      return tutorialType.id
  }

  return null
}))

let function markSeen(tutorialId) {
  settings.mutate(function(set) {
    let saved = (clone (set?[SEEN_ID] ?? {})).__update({
      [tutorialId] = true
    })
    set[SEEN_ID] <- saved
  })
}

let function resetSeen() {
  settings.mutate(@(v) delete v[SEEN_ID])
}

let function startTutorialDelayed() {
  gui_scene.resetTimeout(0.3, function() {
    let tutorialId = visibleTutorialId.value
    if (tutorialId == null)
      return

    local currencyList = viewArmyCurrency.value
      .filter(@(_, c) getTutorialType(c)?.id == tutorialId)
    if (currencyList.len() == 0)
      return

    currencyList = currencyList.keys()
    if (currencyList.len() > 1) {
      currencyList = currencyList.sort(@(a,b)
        getCurrencyPresentation(a).order <=> getCurrencyPresentation(b).order)
    }

    canRunTutorial(false)
    mkLogisticsPromoMsgbox(currencyList,
      [{
        text = loc("btn/gotoLogistics")
        action = function() {
          markSeen(tutorialId)
          setCurSection("SHOP")
        }
      }])
  })
}

visibleTutorialId.subscribe(@(id)
  id != null ? startTutorialDelayed() : null)

console_register_command(resetSeen, "meta.resetSeenOrders")
