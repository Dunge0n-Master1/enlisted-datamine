from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { mkOnlinePersistentFlag, mkOnlinePersistentWatched
} = require("%enlist/options/mkOnlinePersistentFlag.nut")
let {
  seenShopItems, excludeShopItemSeen, getSeenStatus, SeenMarks
} = require("unseenShopItems.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { getShopUrl, getUrlByGuid } = require("%enlist/shop/shopUrls.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { curSection, setCurSection } = require("%enlist/mainMenu/sectionsState.nut")
let {hasClientPermission} = require("%enlSqGlob/client_user_rights.nut")
let { marketIds } = require("%enlist/shop/goodsAndPurchases_pc.nut")
let { curArmyData, curArmy, curCampItemsCount, armySquadsById, armyItemCountByTpl, curCampaign
} = require("%enlist/soldiers/model/state.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { hasCurArmyReserve } = require("%enlist/soldiers/model/reserve.nut")
let { buy_shop_items, buy_shop_offer, barter_shop_items, check_purchases,
  buy_shop_items_list, barter_shop_items_list
} = require("%enlist/meta/clientApi.nut")
let { purchasesCount, curArmiesList } = require("%enlist/meta/profile.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { is_pc, is_sony } = require("%dngscripts/platform.nut")
let { openConsumable, openBundle, openBundles
} = require("%enlist/consoleStore/consoleStore.nut")
let { needNewItemsWindow } = require("%enlist/soldiers/model/newItemsToShow.nut")
let {
  removeCrateContent, requestedCratesContent, itemToShopItem, getShopListForItem
} = require("%enlist/soldiers/model/cratesContent.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let { currencyPresentation } = require("currencyPresentation.nut")
let checkPurchases = require("%enlist/shop/checkPurchases.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { shopItemsBase, shopItems, shopDiscountGen
} = require("shopItems.nut")
let { CAMPAIGN_NONE, isCampaignBought } = require("%enlist/campaigns/campaignConfig.nut")
let qrWindow = require("%enlist/mainMenu/qrWindow.nut")
let { isPlayerRecommendedEmailRegistration } = require("%enlist/profile/profileCountry.nut")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let { PSNAllowShowQRCodeStore } = require("%enlist/featureFlags.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { classSlotLocksByArmy } = require("%enlist/researches/researchesSummary.nut")

const SHOP_SECTION = "SHOP"
let hasShopSection = Computed(@() !(disabledSectionsData.value?.LOGISTICS ?? false))

let shopOrdersUsed = mkOnlinePersistentFlag("hasShopOrdersUsed")
let hasShopOrdersUsed = shopOrdersUsed.flag
let shopOrdersUsedActivate = shopOrdersUsed.activate

let needGoToManagementBtn = Watched(false)
let isDebugShowPermission = hasClientPermission("debug_shop_show")

let marketIdList = keepref(Computed(@() shopItemsBase.value.values()
  .reduce(function(res, item) {
    if ((item?.pcLinkGuid ?? "") != "")
      res.append({ guid = item.pcLinkGuid })
    return res
  }, [] )))

marketIds(marketIdList.value)
marketIdList.subscribe(@(v) marketIds(v))

let shopGroupItemsChain = mkWatched(persist, "shopGroupItemsChain", [])
curArmy.subscribe(@(_) shopGroupItemsChain([]))

let shopConfig = Computed(@() configs.value?.shop_config ?? {})
let purchaseInProgress = Watched(null)
let shopItemToShow = Watched(null)
let shopItemsToHighlight = Watched(null)

curSection.subscribe(function(s) {
  if (s != SHOP_SECTION){
    shopGroupItemsChain([])
    shopItemsToHighlight(null)
    shopItemToShow(null)
  }
})

//wait till new items window close, to avoid situation
//when player bought something more right before show new items,
//and think that he miss currency.
let purchaseIsPossible = Computed(@() purchaseInProgress.value == null
  && !needNewItemsWindow.value)

let function setDiscountUpdateTimer(items){
  let curTime = serverTime.value
  let nextDiscountTimer = items.reduce(function(res, item){
    let curInterval = item?.discountIntervalTs ?? []
    if (curInterval.len() == 0)
      return res
    let [from, to = 0] = curInterval
    if (from > curTime)
      res = res == 0 ? from : min(res, from)
    if (to > curTime)
      res = res == 0 ? to : min(res, to)
    return res
  }, 0)
  if (nextDiscountTimer > curTime)
    gui_scene.resetTimeout(nextDiscountTimer - curTime,
      @() shopDiscountGen(shopDiscountGen.value + 1))
}

shopItems.subscribe(setDiscountUpdateTimer)
setDiscountUpdateTimer(shopItems.value)

let curSwitchTime = Watched(0)

let function updateSwitchTime(...) {
  let currentTs = serverTime.value
  let nextTime = shopItems.value.reduce(function(firstTs, item) {
    let { showIntervalTs = null } = item
    if ((showIntervalTs?.len() ?? 0) == 0)
      return firstTs

    let [from, to = 0] = showIntervalTs
    return (currentTs < from && (from < firstTs || firstTs == 0)) ? from
      : (currentTs < to && (to < firstTs || firstTs == 0)) ? to
      : firstTs
  }, 0) - currentTs
  if (nextTime > 0)
    gui_scene.resetTimeout(nextTime, updateSwitchTime)
  curSwitchTime(currentTs)
}

serverTime.subscribe(function(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  updateSwitchTime()
})
shopItems.subscribe(updateSwitchTime)

let shownByTimestamp = Computed(function() {
  let res = {}
  let ts = curSwitchTime.value
  foreach (id, item in shopItems.value) {
    let { showIntervalTs = null } = item
    if ((showIntervalTs?.len() ?? 0) == 0)
      continue

    let [from, to = 0] = showIntervalTs
    if (from <= ts && (ts < to || to == 0))
      res[id] <- true
  }
  return res
})

let function canBarterItem(item, armyItemCount) {
  foreach (payItemTpl, cost in item.curItemCost)
    if ((armyItemCount?[payItemTpl] ?? 0) < cost)
      return false
  return true
}

let isTemporaryVisible = @(itemId, shopItem, itemCount, itemsByTime)
  ((shopItem?.isVisibleIfCanBarter ?? false) && canBarterItem(shopItem, itemCount))
    || itemId in itemsByTime

let isAvailableBySquads = function(shopItem, squadsByArmyV) {
  foreach (squadData in shopItem?.squads ?? []) {
    let { id, squadId = null, armyId = null } = squadData
    let squad = squadsByArmyV?[armyId][squadId ?? id]
    if (squad != null && (squad?.expireTime ?? 0) == 0)
      return false
  }
  return true
}

let isAvailableByLimit = @(sItem, purchases)
  (sItem?.limit ?? 0) <= 0 || sItem.limit > (purchases?[sItem?.id].amount ?? 0)

let isAvailableByPermission = @(sItem, isDebugShow)
  !(sItem?.isShowDebugOnly ?? false) || isDebugShow

let getMinRequiredArmyLevel = @(goods) goods.reduce(function(res, sItem) {
  let level = sItem?.requirements.armyLevel ?? 0
  return level <= 0 ? res
    : res <= 0 ? level
    : min(level, res)
}, 0)

// TODO has duplicate factory at shopState.nut; should be used instead of continuous computations
let curArmyItemsPrefiltered = Computed(function() {
  let armyId = curArmyData.value?.guid
  let itemCount = armyItemCountByTpl.value ?? {}
  let itemsByTime = shownByTimestamp.value
  let squadsById = armySquadsById.value
  let purchases = purchasesCount.value
  let notFreemium = isCampaignBought.value
  let debugPermission = isDebugShowPermission.value
  return shopItems.value.filter(function(item, id) {
    let { armies = [], isHidden = false, isHiddenOnChinese = false, requirements = {} } = item
    let { campaignGroup = CAMPAIGN_NONE } = requirements
    return (armies.contains(armyId) || armies.len() == 0)
      && (!isHidden || isTemporaryVisible(id, item, itemCount, itemsByTime))
      && !(isChineseVersion && isHiddenOnChinese)
      && isAvailableBySquads(item, squadsById)
      && isAvailableByLimit(item, purchases)
      && isAvailableByPermission(item, debugPermission)
      && (notFreemium || campaignGroup == CAMPAIGN_NONE)
  })
})

let curArmyShopInfo = Computed(function() {
  let itemCount = armyItemCountByTpl.value ?? {}
  let itemsByTime = shownByTimestamp.value
  local goods = curArmyItemsPrefiltered.value
  let armies = curArmiesList.value
  let unlockLevel = getMinRequiredArmyLevel(
    shopItems.value.filter(@(i) i?.armies.findvalue(@(a) armies.contains(a))))
  let hasTemporary = goods.findindex(@(i, id)
    isTemporaryVisible(id, i, itemCount, itemsByTime)) != null
  goods = goods.values()
  return { unlockLevel, goods, hasTemporary }
})

let curArmyShowcase = Computed(function() {
  let curArmyLvl = curArmyData.value?.level ?? 0
  let goods = curArmyItemsPrefiltered.value
    .filter(@(i)
      ((i?.requirements.armyLevel ?? 0) == 0 || (i?.requirements.armyLevel ?? 0) >= curArmyLvl)
      && (i?.offerContainer ?? "") == ""
      && (i?.showcaseLevel ?? 0) > 0)
  let res = {}
  foreach (goodGuid, good in goods) {
    let level = good?.showcaseLevel ?? 0
    res[level] <- (res?[level] ?? []).append(goodGuid)
  }
  return res
})

let curArmyShopItems = Computed(@() curArmyShopInfo.value.goods)

let function trimTree(node, curFolder){
  let res = []
  for (local i=0; i<node.childItems.len(); i++){
    local subNode = node.childItems[i]
    if ((subNode?.offerContainer ?? "") == "")
      res.append(subNode)
    else {
      subNode = trimTree(subNode, curFolder)
      if (subNode)
        res.append(subNode)
    }
  }
  if (res.len() == 0)
    return null

  if (res.len() == 1 && node?.id != curFolder?.id)
    return res[0]

  node.childItems = res
  return node
}

let function getGroup(groups, id) {
  if (id not in groups)
    groups[id] <- { childItems = [] }
  return groups[id]
}

let function getCurShopTree(allItems){
  let groups = {}
  let rootItems = []

  foreach (item in allItems) {
    let { offerGroup = "", offerContainer = ""} = item
    let isContainer = offerContainer != ""
    let isInGroup = offerGroup != ""
    local itemToAppend = item

    if (isContainer)
      itemToAppend = getGroup(groups, offerContainer).__update(item)

    if (isInGroup)
      getGroup(groups, offerGroup).childItems.append(itemToAppend)

    else
      rootItems.append(itemToAppend)
  }
  return rootItems
}

let flatFolder = @(node) node.reduce(@(res, child) res.append(child), [])

let curFullTree = Computed(@() getCurShopTree(curArmyShopItems.value))

let curArmyShopFolder = Computed(function(){
  let chain = shopGroupItemsChain.value
  let fullTree = clone curFullTree.value
  local tree = trimTree({childItems = fullTree}, chain?[chain.len()-1])
  let chainLen = (chain?.len() ?? 0)
  if (chainLen == 0)
    return { path = [], items = flatFolder(tree?.childItems ?? []) }

  local curChild = null
  local curFolder = null
  local depth = 0
  do {
    curFolder = chain[depth].offerContainer
    curChild = tree.childItems.findvalue(@(v) v?.offerContainer == curFolder)
    if (curChild){
      depth++
      tree = curChild
    }
  } while (curChild && depth < chainLen)
  return { path = chain.slice(0, depth), items = flatFolder(tree.childItems) }
})


let function getAllChildItems(folderItem, withFolders = false){
  let res = []
  foreach (item in folderItem.childItems){
    let { offerContainer = "" } = item
    if (offerContainer == "" || withFolders)
      res.append(item)
    if (offerContainer != "")
      res.extend(getAllChildItems(item, withFolders))
  }
  return res
}


let function hasGoldValue(item){
  if ((item?.offerContainer ?? "") == "")
    return item?.shopItemPrice.currencyId == "EnlistedGold"
  foreach (subItem in item.childItems)
    if (hasGoldValue(subItem))
      return true
  return false
}


let viewCurrencies = Watched(null)
let realCurrencies = Computed(function() {
  let itemsCount = curCampItemsCount.value
  let res = {}
  foreach (currencyTpl, _ in currencyPresentation)
    res[currencyTpl] <- itemsCount?[currencyTpl] ?? 0

  return res
})

let function fillViewCurrencies(_) {
  viewCurrencies(clone realCurrencies.value)
}

foreach (v in [isLoggedIn, curCampaign])
  v.subscribe(fillViewCurrencies)

let curShopCurrencies = Computed(@()
  curArmyShopItems.value.reduce(@(res, shopItem) res.__update(shopItem?.itemCost ?? {}), {}).keys())

let viewArmyCurrency = Computed(function() {
  let res = {}
  foreach (currencyTpl in curShopCurrencies.value)
    res[currencyTpl] <- viewCurrencies.value?[currencyTpl] ?? 0

  let armyId = curArmy.value
  return res.filter(@(count, tpl) count > 0
    || !(allItemTemplates.value?[armyId][tpl].isZeroHidden ?? true))
})


let function getBuyRequirementError(shopItem) {
  let requirements = shopItem?.requirements
  if ((requirements?.hasArmyReserve ?? false) && !hasCurArmyReserve.value)
    return {
      text = loc("shop/freePlaceForReserve")
      solvableByPremium = !hasPremium.value
    }
  return null
}

let curAvailableShopItems = Computed(function() {
  let { level = 0 } = curArmyData.value
  return curArmyShopItems.value.filter(@(item) (item?.offerContainer ?? "") == ""
    && (item?.requirements.armyLevel ?? 0) <= level
  )
})

let function getUnseenGuids(tree, res, seen, avail) {
  foreach (branch in tree) {
    let { guid, childItems = [] } = branch
    if (childItems.len() == 0) {
      if (guid not in seen && guid in avail)
        res[guid] <- true
      continue
    }

    let treeRes = {}
    getUnseenGuids(childItems, treeRes, seen, avail)
    if (treeRes.len() == 0)
      continue

    res.__update(treeRes)
    res[guid] <- true
  }
  return res
}

let curUnseenAvailShopGuids = Computed(function() {
  let avail = {}
  foreach (item in curAvailableShopItems.value)
    if ((item?.featuredWeight ?? 0) == 0)
      avail[item.guid] <- true
  let seen = seenShopItems.value.seen?[curArmy.value] ?? {}
  let fullTree = curFullTree.value

  return getUnseenGuids(fullTree, {}, seen, avail)
})

curAvailableShopItems.subscribe(function(items) {
  let armyId = curArmy.value

  let seen = seenShopItems.value.seen?[armyId] ?? {}
  if (seen.len() != 0) {
    let excludeList = seen
      .filter(@(_, guid) items.findindex(@(i) i.guid == guid) == null)
      .keys()

    if (excludeList.len() != 0)
      gui_scene.resetTimeout(0.1, @() excludeShopItemSeen(armyId, excludeList))
  }
})

let premiumProducts = Computed(@()
  shopItems.value.filter(@(i) (i?.squads.len() ?? 0) == 0 // keep clean premium items only
    && (i?.armies.len() ?? 0) == 0
    && (i?.crates.len() ?? 0) == 0
    && (i?.premiumDays ?? 0) > 0
    && (i?.curShopItemPrice.price ?? 0) > 0
    && (i?.curShopItemPrice.currencyId ?? "") != ""
  )
  .values()
  .sort(@(a, b) (a?.premiumDays ?? 0) <=> (b?.premiumDays ?? 0))
)

let function barterShopItem(shopItem, payData, count = 1) {
  if (purchaseInProgress.value != null)
    return

  purchaseInProgress(shopItem)
  shopItemToShow(shopItem)
  barter_shop_items(curArmy.value, shopItem.guid, payData, count, function(_) {
    purchaseInProgress(null)
    removeCrateContent(shopItem?.crates ?? [])
    shopOrdersUsedActivate()
  })
}

let function barterShopItemList(shopItemsList, itemData, payData, cb) {
  if (purchaseInProgress.value != null)
    return

  purchaseInProgress(shopItemsList.top())

  barter_shop_items_list(curArmy.value, itemData, payData, function(res) {
    purchaseInProgress(null)
    cb?(res?.error == null)
  })

}

let function buyShopItem(shopItem, currencyId, price, cb = null, count = 1) {
  if (purchaseInProgress.value != null)
    return

  purchaseInProgress(shopItem)
  shopItemToShow(shopItem)

  buy_shop_items(curArmy.value, shopItem.guid, currencyId, price, count, function(res) {
    purchaseInProgress(null)
    removeCrateContent(shopItem?.crates ?? [])
    cb?(res?.error == null)
  })
}

let function buyShopOffer(shopItem, currencyId, price, cb = null, pOfferGuid = null) {
  if (purchaseInProgress.value != null)
    return

  purchaseInProgress(shopItem)
  shopItemToShow(shopItem)

  buy_shop_offer(curArmy.value, shopItem.guid, currencyId, price, pOfferGuid, function(res) {
    purchaseInProgress(null)
    removeCrateContent(shopItem?.crates ?? [])
    cb?(res?.error == null)
  })
}

let function buyShopItemList(shopItemsList, itemData, payData, cb) {
  if (purchaseInProgress.value != null)
    return

  purchaseInProgress(shopItemsList.top())

  buy_shop_items_list(curArmy.value, itemData, payData, function(res) {
    purchaseInProgress(null)
    cb?(res?.error == null)
  })
}

let function openPurchaseUrl(url) {
  openUrl(url)
  checkPurchases()
}

let buyItemByGuid = !is_pc? function(_) {
    openBundles()
    checkPurchases()
    return true
  }
  : function(guid) {
      let url = getUrlByGuid(guid) ?? getShopUrl()
      if (url == null)
        return false

      openPurchaseUrl(url)
      return true
    }

let function buyItemByStoreId(storeId) {
  openBundle(storeId)
  checkPurchases()
}

let function buyCurrency(currency) {
  if (is_pc) {
    openPurchaseUrl(currency?.purchaseUrl ?? "")
    return
  }

  if ((!is_sony || PSNAllowShowQRCodeStore.value) && isPlayerRecommendedEmailRegistration() && gameLanguage == "Russian") {
    qrWindow({
        header = currency?.locId ? loc(currency.locId) : ""
        url = currency?.qrConsoleUrl ?? "",
        needShowRealUrl = false,
        desc = currency?.qrDesc ? loc(currency.qrDesc) : ""
      },
      function() {
        openConsumable()
        checkPurchases()
      }
    )
    return
  }

  openConsumable()
  checkPurchases()
}

userInfo.subscribe(function(u) {
  if (u != null)
    check_purchases()
})

let function blinkCurrencies() {
  foreach (currencyTpl, count in viewArmyCurrency.value)
    if (count > 0)
      anim_start($"blink_{currencyTpl}")
}

let function setupBlinkCurrencies(...) {
  if (curSection.value != SHOP_SECTION || hasShopOrdersUsed.value)
    gui_scene.clearTimer(blinkCurrencies)
  else
    gui_scene.setInterval(2.5, blinkCurrencies)
}

setupBlinkCurrencies()
foreach (w in [curSection, hasShopOrdersUsed])
  w.subscribe(setupBlinkCurrencies)

let function shopItemContentCtor(shopItem) {
  if ((shopItem?.crates.len() ?? 0) == 0)
    return null
  return Computed(function() {
    let crate = shopItem.crates.findvalue(@(c) c.armyId == curArmy.value) ?? shopItem.crates[0]
    let { armyId, id } = crate
    let content = requestedCratesContent.value?[armyId][id]
    if (content)
      return { id, armyId, content }
    return null
  })
}

let function shopItemContentArrayCtor(shopItemW) {
  return Computed(function(){
    let res = []
    foreach (crate in shopItemW.value?.crates ?? []) {
      let { armyId, id } = crate
      let content = requestedCratesContent.value?[armyId][id]
      if (content)
        res.append({ id, armyId, content })
    }
    return res
  })
}

let isShopVisible = mkOnlinePersistentWatched("isShopVisible",
  Computed(@() (curArmyData.value?.level ?? 0) >= curArmyShopInfo.value.unlockLevel))

local function getShopItemPath(shopItem, allShopItems){
  let path = []
  local curOfferGroup = shopItem?.offerGroup ?? ""
  while(curOfferGroup != ""){
    shopItem = allShopItems.findvalue(@(v) v?.offerContainer == curOfferGroup)
    path.insert(0, shopItem)
    curOfferGroup = shopItem?.offerGroup ?? ""
  }
  return path
}

let getShopItems = @(tpl, armyId, itemToShopItemV, allItemTemplatesV, curArmyItemsPrefilteredV)
  getShopListForItem(tpl, armyId, itemToShopItemV, allItemTemplatesV)
    .map(@(shopItemId) curArmyItemsPrefilteredV?[shopItemId])

let getShopItemsList = @(tpl) getShopItems(tpl, curArmy.value,
  itemToShopItem.value, allItemTemplates.value, curArmyItemsPrefiltered.value)

let getShopItemsCmp = @(tpl) Computed(@() getShopItems(tpl, curArmy.value,
  itemToShopItem.value, allItemTemplates.value, curArmyItemsPrefiltered.value))

local function openAndHighlightItems(targetShopItems, allShopItems){
  local longestPathIdx = -1
  local targetPath = []
  targetShopItems.each(function(v, i){
    let path = getShopItemPath(v, allShopItems)
    if (path.len() > targetPath.len()){
      targetPath = path
      longestPathIdx = i
    }
  })
  if (longestPathIdx != -1) {
    targetShopItems = clone targetShopItems
    targetShopItems.insert(0, targetShopItems.remove(longestPathIdx))
  }
  shopItemsToHighlight(targetShopItems)
  shopGroupItemsChain(targetPath)
  setCurSection(SHOP_SECTION)
}

let setCurArmyShopPath = @(path) shopGroupItemsChain(path)

let function setCurArmyShopFolder(folderId){
  if (folderId == null) {
    shopGroupItemsChain([])
    return
  }

  let chain = shopGroupItemsChain.value
  let groupIdx = chain.findindex(@(v) v?.offerContainer == folderId)
  if (groupIdx != null)
    shopGroupItemsChain(shopGroupItemsChain.value.slice(0, groupIdx + 1))
}

let findSquadShopItem = @(armyId, squadId)
  curArmyShopItems.value.findvalue(function(sItem) {
    let { squads = [] } = sItem
    return squads.len() == 1 && squads[0].armyId == armyId && squads[0].id == squadId
  })

let notOpenedShopItems = Computed(function() {
  let opened = seenShopItems.value?.opened[curArmy.value] ?? {}
  let notOpenedGuids = curAvailableShopItems.value
    .filter(@(item) getSeenStatus(opened?[item.guid]) == SeenMarks.NOT_SEEN)
    .map(@(item) item.guid)
  return notOpenedGuids
})


let isItemsShopOpened = mkWatched(persist, "isItemsShopOpened", false)
let itemsToPresent = Watched({})

let function addToPresentList(itemsList) {
  itemsToPresent.mutate(function(presentData) {
    foreach (item in itemsList) {
      let armyId = getLinkedArmyName(item)
      if (armyId not in presentData)
        presentData[armyId] <- {}

      let { basetpl, count = 1 } = item
      presentData[armyId][basetpl] <- (presentData[armyId]?[basetpl] ?? 0) + count
    }
  })
}


let curSuitableItemTypes = Computed(function() {
  let armyId = curArmyData.value?.guid
  let { sClass = null, equipScheme = {} } = curSoldierInfo.value
  let lockedSlots = classSlotLocksByArmy.value?[armyId][sClass] ?? []
  let res = {}
  foreach (slotId, scheme in equipScheme)
    if (lockedSlots.indexof(slotId) == null)
      foreach (itemType in scheme.itemTypes)
        res[itemType] <- true

  return res
})


let curSuitableShopItems = Computed(function() {
  let armyId = curArmyData.value?.guid
  let itemTypes = curSuitableItemTypes.value
  let res = {}
  let templates = allItemTemplates.value?[armyId] ?? {}
  foreach (tpl, shopGuids in itemToShopItem.value?[armyId] ?? {})
    if (itemTypes?[templates?[tpl].itemtype] ?? false)
      foreach (shopGuid in shopGuids)
        res[shopGuid] <- true

  return res
})

return {
  SHOP_SECTION
  hasShopSection
  shopConfig
  curArmyShopInfo
  curArmyShowcase
  curArmyShopItems
  curArmyItemsPrefiltered
  realCurrencies
  viewCurrencies
  viewArmyCurrency
  purchaseInProgress
  shopItemToShow
  shopItemsToHighlight
  purchaseIsPossible
  buyShopItem
  buyShopOffer
  barterShopItem
  buyItemByGuid
  buyItemByStoreId
  buyCurrency
  buyShopItemList
  barterShopItemList
  getBuyRequirementError
  isAvailableByLimit
  curUnseenAvailShopGuids
  premiumProducts
  shopItemContentCtor
  shopItemContentArrayCtor
  isShopVisible
  getShopItemsList
  getShopItemsCmp
  openAndHighlightItems
  curArmyShopFolder
  setCurArmyShopPath
  setCurArmyShopFolder
  getAllChildItems
  hasGoldValue
  findSquadShopItem
  notOpenedShopItems
  requestedCratesContent
  isItemsShopOpened
  itemsToPresent
  addToPresentList
  curSuitableItemTypes
  curSuitableShopItems
  needGoToManagementBtn
  curAvailableShopItems
}
