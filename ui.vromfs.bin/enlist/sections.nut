from "%enlSqGlob/ui_library.nut" import *

let soldiersList = require("soldiers/soldiersList.ui.nut")
let armyUnlocksUi = require("soldiers/armyUnlocksUi.nut")
let researchesList = require("researches/researchesList.ui.nut")
let mkNotifier = require("%enlist/components/mkNotifier.nut")
let armyShopUi = require("shop/armyShopUi.nut")
let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { setSectionsSorted, curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { hasResearchesSection } = require("researches/researchesState.nut")
let { unseenResearches } = require("researches/unseenResearches.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let {
  curUnseenAvailShopGuids, hasUnseenCurrencies, isShopVisible, hasShopSection,
  curArmyShopItems, notOpenedShopItems
} = require("shop/armyShopState.nut")
let { nextTutorialUnlock, showGetUnlockTutorial
} = require("%enlist/tutorial/notReceivedUnlockTutorial.nut")
let { hasCampaignSection, hasCurArmyUnlockAlert
} = require("soldiers/model/armyUnlocksState.nut")
let { hasLevelDiscount, curLevelDiscount
} = require("%enlist/campaigns/armiesConfig.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { getStoreUrl, getEventUrl} = require("%ui/networkedUrls.nut")
let { isEventUnseen, markEventSeen } = require("gameModes/eventUnseenSignState.nut")
let { markShopItemOpened } = require("%enlist/shop/unseenShopItems.nut")


let hasCampaignAlert = Computed(@() hasCampaignSection.value
  && isCurCampaignProgressUnlocked.value
  && hasCurArmyUnlockAlert.value )

let hasResearchesAlert = Computed(@() hasResearchesSection.value
  && isCurCampaignProgressUnlocked.value
  && unseenResearches.value.findindex(@(a) a.len() > 0) != null)

let hasUnseenShopItems = Computed(@() hasUnseenCurrencies.value
  || curUnseenAvailShopGuids.value.len() > 0)

let maxCurArmyDiscount = Computed(function() {
  let lvl = curArmyData.value?.level ?? 0
  return curArmyShopItems.value.reduce(@(res, val)
    (val?.requirements.armyLevel ?? 0) > lvl
      ? res
      : max(res, (val?.discountInPercent ?? 0)), 0)
})

let hasShopAlert = Computed(@() hasShopSection.value
  && isCurCampaignProgressUnlocked.value
  && isShopVisible.value
  && (maxCurArmyDiscount.value > 0 || hasUnseenShopItems.value))

let discountBg = { color = 0xffff313b }

let shopAlertBlink = Computed(@()
  curSection.value != "SHOP" && notOpenedShopItems.value.len() > 0)

let function shopAlertUi() {
  let override = shopAlertBlink.value
    ? { key = "blink_on" }
    : { key = "blink_off", animations = null }
  let percents = maxCurArmyDiscount.value
  let children = percents > 0
      ? mkNotifier(loc("shop/discount", { percents }), {},
          override.__merge(discountBg), tiny_txt)
    : hasShopAlert.value
      ? mkNotifier(loc("hint/newShopItemsAvailable"), {}, override, tiny_txt)
    : null
  return {
    watch = [hasShopAlert, maxCurArmyDiscount, shopAlertBlink]
    hplace = ALIGN_RIGHT
    pos = [0, hdpx(30)]
    children
  }
}

let sections = [

  {
    locId = "menu/soldier"
    content = soldiersList
    id = "SOLDIERS"
    camera = "soldiers"
  }

  {
    locId = "menu/campaignRewards"
    descId = "menu/campaignRewardsDesc"
    content = armyUnlocksUi
    id = "SQUADS"
    camera = "researches"
    addChild = @() {
      watch = [hasLevelDiscount, curLevelDiscount, hasCampaignAlert]
      hplace = ALIGN_RIGHT
      pos = [0, hdpx(30)]
      children = hasLevelDiscount.value ? mkNotifier(loc("shop/discount",
          { percents = curLevelDiscount.value }), {}, discountBg, tiny_txt)
        : hasCampaignAlert.value ? mkNotifier(loc("hint/takeReward"),
          {}, {}, tiny_txt)
        : null
    }
    onExitCb = function() {
      if (!hasCampaignAlert.value)
        return true

      let unlock = nextTutorialUnlock.value
      if (unlock != null) {
        showGetUnlockTutorial(unlock)
        return false
      }

      return true
    }
  }

  {
    locId = "menu/researches"
    descId = "menu/researchesDesc"
    content = researchesList
    id = "RESEARCHES"
    camera = "researches"
    unseenWatch = hasResearchesAlert
  }

  {
    locId = "menu/enlistedShop"
    content = armyShopUi
    id = "SHOP"
    camera = "researches"
    addChild = shopAlertUi
    onExitCb = function() {
      markShopItemOpened(curArmyData.value?.guid, notOpenedShopItems.value)
      return true
    }
  }
]

if (getStoreUrl() != null)
  sections.append({
    locId = "menu/store"
    id = "STORE"
    selectable = false
    onClickCb = @() openUrl(getStoreUrl())
  })

if (getEventUrl() != null)
  sections.append({
    locId = "menu/event"
    id = "EVENT"
    selectable = false
    onClickCb = function(){
      openUrl(getEventUrl())
      markEventSeen()
    }
    unseenWatch = isEventUnseen
  })

setSectionsSorted(sections)
