from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { curArmy, armySquadsById, armyItemCountByTpl } = require("%enlist/soldiers/model/state.nut")
let { shopItems } = require("shopItems.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let { curUnseenAvailShopGuids, notOpenedShopItems } = require("armyShopState.nut")
let { CAMPAIGN_NONE, isCampaignBought } = require("%enlist/campaigns/campaignConfig.nut")

let isDebugShowPermission = hasClientPermission("debug_shop_show")

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

let function onServerTime(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  updateSwitchTime()
}


let function onShopAttach(){
  serverTime.subscribe(onServerTime)
  shopItems.subscribe(updateSwitchTime)
}

let function onShopDetach(){
  serverTime.unsubscribe(onServerTime)
  shopItems.unsubscribe(updateSwitchTime)
}


let curGroupIdx = Watched(0)
let curFeaturedIdx = Watched(0)
let chapterIdx = Watched(-1)
let curSelectionShop = Watched(null)

let function mkShopState() {
  let shopConfig = Computed(@() configs.value?.shop_config ?? {})

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

  let curArmyItemsPrefiltered = Computed(function() {
    let armyId = curArmy.value
    let itemCount = armyItemCountByTpl.value ?? {}
    let itemsByTime = shownByTimestamp.value
    let squadsById = armySquadsById.value
    let purchases = purchasesCount.value
    let notFreemium = isCampaignBought.value
    let debugPermission = isDebugShowPermission.value
    let shopItemsList = shopItems.value.filter(function(item, id) {
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
    return shopItemsList
  })

  let mainOrders = {
    weapon_order = true
    soldier_order = true
    weapon_order_silver = true
    soldier_order_silver = true
    weapon_order_gold = true
    soldier_order_gold = true
    vehicle_with_skin_order_gold = true
  }

  let function hasPriceContainsGold(shopItem) {
    let { price = 0, currencyId = "" } = shopItem?.shopItemPrice
    return currencyId == "EnlistedGold" && price > 0
  }

  let function hasPriceContainsOrders(shopItem) {
    let { itemCost = {} } = shopItem
    return itemCost.len() > 0
  }

  let function hasPriceContainsSpecOrders(shopItem) {
    foreach (orderId, price in shopItem?.itemCost ?? {})
      if (orderId not in mainOrders && price > 0)
        return true
    return false
  }

  let function isExternalPurchase(shopItem) {
    let { shop_price = 0, shop_price_curr = "", storeId = "", devStoreId = "" } = shopItem
    return (shop_price_curr != "" && shop_price > 0) //PC type
      || storeId != "" || devStoreId != ""//Consoles type
  }


  let bpGroupsChapters = {
    weapon_battlepass_group = 0
    soldier_battlepass_group = 1
    vehicle_battlepass_group = 2
  }

  let itemsGroupsChapters = {
    wpack_silver_pistol_group = 0
    wpack_silver_rifle_group = 1
    wpack_silver_submachine_gun_group = 2
    wpack_silver_special_group = 3
    wpack_group = 4
    item_group = 5
  }


  let sortItemsFunc = @(a, b) (a?.viewOrder ?? 1000) <=> (b?.viewOrder ?? 1000)
    || (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0)

  let sortFeaturedFunc = @(a, b)
    (a?.featuredWeight ?? 0) <=> (b?.featuredWeight ?? 0)
      || (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0)

  let function getChapterItems(armyItems, chapterScheme) {
    let chapters = chapterScheme.map(@(weigth) { container = null, goods = [], weigth })
    foreach (sItem in armyItems) {
      let { offerContainer = "", offerGroup = "" } = sItem
      if (offerContainer in chapters)
        chapters[offerContainer].container = sItem
      if (offerGroup in chapters)
        chapters[offerGroup].goods.append(sItem)
    }
    chapters.each(@(chapter) chapter.goods.sort(sortItemsFunc))
    return chapters.values().sort(@(a, b) a.weigth <=> b.weigth)
  }

  let armyGroups = [
    {
      id = "premium"
      reqFeatured = true
      filterFunc = @(shopItem) hasPriceContainsSpecOrders(shopItem)
        || (!hasPriceContainsOrders(shopItem)
          && (hasPriceContainsGold(shopItem) || isExternalPurchase(shopItem)))
    }
    {
      id = "battlepass"
      mkChapters = @(armyShopItems) getChapterItems(armyShopItems, bpGroupsChapters)
    }
    {
      id = "weapon"
      locId = "soldierWeaponry"
      mkChapters = @(armyShopItems) getChapterItems(armyShopItems, itemsGroupsChapters)
    }
    {
      id = "soldier"
      locId = "menu/soldier"
      filterFunc = @(shopItem)
        shopItem?.offerGroup == "soldier_silver_group"
    }
  ]


  let curItemsByGroup = Computed(function() {
    let prefilteredItems = curArmyItemsPrefiltered.value
    let res = {}
    foreach (group in armyGroups) {
      let { filterFunc = null, mkChapters = null } = group
      if (mkChapters != null) {
        let groupRes = []
        foreach (chapter in mkChapters(prefilteredItems))
          foreach (sItem in chapter.goods)
            groupRes.append(sItem)
        res[group.id] <- groupRes
      }
      else if (filterFunc != null)
        res[group.id] <- prefilteredItems
          .reduce(function(r, val) {
            if (filterFunc(val))
              r.append(val)
            return r
          }, [])
          .sort(sortItemsFunc)
    }
    return res
  })


  let curShopItemsByGroup = Computed(function() {
    let items = curItemsByGroup.value
    let armyItems = curArmyItemsPrefiltered.value
    return armyGroups.map(function(group) {
      let { mkChapters = null } = group
      return {
        id = group.id
        locId = group?.locId
        goods = (items?[group.id] ?? []).filter(@(item) (item?.featuredWeight ?? 0) == 0)
        chapters = mkChapters?(armyItems)
      }
    })
  })


  let maxDiscountByGroup = Computed(@() curItemsByGroup.value
    .map(@(group) group.reduce(@(r, v) max(r, v?.hideDiscount ? 0 : v?.discountInPercent ?? 0), 0)))

  let specialOfferByGroup = Computed(@() curItemsByGroup.value
    .map(@(group) group
      .findvalue(@(v) (v?.discountInPercent ?? 0) > 0 && v?.showSpecialOfferText) != null))

  let curFeaturedByGroup = Computed(@() curItemsByGroup.value
    .map(@(group) group
      .filter(@(item) (item?.featuredWeight ?? 0) > 0)
      .sort(sortFeaturedFunc)
    ))


  let curShopDataByGroup = Computed(function() {
    let curUnseen = curUnseenAvailShopGuids.value
    let curUnopened = {}
    foreach (guid in notOpenedShopItems.value)
      curUnopened[guid] <- true

    let maxDiscounts = maxDiscountByGroup.value
    let specialOffer = specialOfferByGroup.value
    let res = {}
    foreach (id, group in curItemsByGroup.value)
      res[id] <- {
        hasUnseen = group.findvalue(@(v) v.guid in curUnseen) != null
        unopened = group.filter(@(v) v.guid in curUnopened).map(@(v) v.guid)
        discount = maxDiscounts?[id] ?? 0
        showSpecialOffer = specialOffer?[id] ?? false
      }

    return res
  })

  let function switchGroup() {
    let grCount = curShopItemsByGroup.value.len()
    curGroupIdx((curGroupIdx.value + 1) % grCount)
    chapterIdx(-1)
  }

  let function autoSwitchNavigation() {
    let groups = curShopItemsByGroup.value
    let { group = null, chapter = null } = curSelectionShop.value
    local groupIndex, chapterIndex

    curSelectionShop(null)

    if (chapter)
      foreach (k,v in groups) {
        chapterIndex = v.chapters?.findindex(@(g) g.container?.offerContainer == chapter)
        if (chapterIndex != null) {
          groupIndex = k
          break
        }
      }

    if (group) {
      groupIndex = groups.findindex(@(g) g.id == group)
    }

    if (groupIndex != null)
      curGroupIdx(groupIndex)
    if (chapterIndex != null)
      chapterIdx(chapterIndex)
    // TODO: need add function open item shop
  }

  return {
    curShopItemsByGroup
    curShopDataByGroup
    curFeaturedByGroup
    shopConfig
    switchGroup
    autoSwitchNavigation
  }
}

return {
  mkShopState
  onShopAttach
  onShopDetach
  curGroupIdx
  curFeaturedIdx
  chapterIdx
  curSwitchTime
  setAutoGroup = @(group) curSelectionShop({group})
  setAutoChapter = @(chapter) curSelectionShop({chapter})
}
