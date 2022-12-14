from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { soldiersLook } = require("%enlist/meta/servProfile.nut")
let { outfitSchemes, outfitShopTypes, curArmyOutfit, allOutfitByArmy
} = require("%enlist/soldiers/model/config/outfitConfig.nut")
let { findItemTemplate, allItemTemplates
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { appearanceToRender } = require("%enlist/scene/soldier_tools.nut")
let { curSoldierInfo, soldiersList } = require("model/squadInfoState.nut")
let { apply_outfit, buy_outfit, use_outfit_orders } = require("%enlist/meta/clientApi.nut")
let rand = require("%sqstd/rand.nut")()
let { removeModalWindow } = require("%ui/components/modalWindows.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { isLinkedTo } = require("%enlSqGlob/ui/metalink.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { logerr } = require("dagor.debug")

let isCustomizationWndOpened = Watched(false)
let isPurchasing = Watched(false)
let currentItemPart = mkWatched(persist, "currentItemPart", "")
let curCustomizationItem = mkWatched(persist, "curCustomizationItem", null)
let customizationToApply = mkWatched(persist, "customizationToApply", {})
let itemsToBuy = mkWatched(persist, "itemsToBuy", {})
let oldSoldiersLook = mkWatched(persist, "oldSoldiersLook", {})
let isMultiplePurchasing = mkWatched(persist, "isMultiplePurchasing", false)

const APPEARANCE_ORDER_TPL = "appearance_change_order"
const PURCHASE_WND_UID = "PURCHASE_WND"

let customizedSoldierInfo = Computed(@() isInBattleState.value ? null : curSoldierInfo.value)

let function getCustomizeScheme(squadsCfg, outfitCfg, armyId, squadId) {
  let { soldierTemplatePreset = null } = squadsCfg?[armyId][squadId]
  return outfitCfg?[armyId][soldierTemplatePreset] ?? {}
}

currentItemPart.subscribe(@(v)
  curCustomizationItem(customizationToApply.value?[v]))

let customizationItems = Computed(@()
  customizationToApply.value.reduce(function(res, v) {res[v] <- true; return res;}, {})
)

let closePurchaseWnd = function(){
  isMultiplePurchasing(false)
  removeModalWindow(PURCHASE_WND_UID)
}
isPurchasing.subscribe(@(v) v ? null : closePurchaseWnd())

customizationToApply.subscribe(function(v){
  if (customizedSoldierInfo.value == null || v.len() <= 0) {
    gui_scene.setTimeout(0.1, @() appearanceToRender(null))
    return
  }
  appearanceToRender(v)
})

let freeItemsBySquad = Computed(function(){
  let { armyId = null } = customizedSoldierInfo.value
  local result = {}
  if (armyId == null)
    return result

  let linkedItems = allOutfitByArmy.value?[armyId] ?? []
  let unlinkedItems = {}
  curArmyOutfit.value.each(@(val) unlinkedItems[val.basetpl] <- true)
  foreach (soldier in soldiersList.value){
    let sGuid = soldier.guid
    let res = {}
    result[sGuid] <- res
    let defaultItems = soldiersLook.value?[sGuid].items ?? {}
    defaultItems.each(@(val) res[val] <- true)
    res.__update(unlinkedItems)
    linkedItems.each(function(val){
      if (isLinkedTo(val, sGuid))
        res[val.basetpl] <- true
    })
  }
  return result
})

let curSoldierItemsPrice = Computed(function(){
  let { armyId = null, squadId = null, guid = null } = customizedSoldierInfo.value
  let res = {}
  if (armyId == null || squadId == null || guid == null)
    return res

  let itemTypes = outfitShopTypes.value
  let allItems = getCustomizeScheme(squadsCfgById.value, outfitSchemes.value, armyId, squadId)
  allItems.each(@(val) val.each(function(item){
    if (item in freeItemsBySquad.value?[guid])
      return
    let { itemsubtype = null } = findItemTemplate(allItemTemplates, armyId, item)
    let curItemPrice = itemTypes?[itemsubtype]
    let isHidden = (curItemPrice ?? {}).findvalue(@(val) val?.isZeroHidden) != null
    if (curItemPrice != null && !isHidden)
      res[item] <- curItemPrice
  }))

  return res
})


let premiumItemsCount = Computed(function(){
  let res = {}
  let { armyId = null, guid = null} = customizedSoldierInfo.value
  if (armyId == null || guid == null)
    return res

  let linkedItems = allOutfitByArmy.value?[armyId] ?? []
  foreach (item in linkedItems)
    if (item.links.len() == 1 || guid in item.links)
      res[item.basetpl] <- (res?[item.basetpl] ?? 0) + 1

  return res
})


let function checkIfCanBuy(item){
  let { armyId = null, guid = null } = customizedSoldierInfo.value
  let curItemPart = currentItemPart.value
  if (armyId == null || guid == null || curItemPart == null)
    return

  let hasPrice = curSoldierItemsPrice.value?[item] != null
  if (hasPrice && item not in freeItemsBySquad.value[guid])
      itemsToBuy.mutate(@(v) v[curItemPart] <- item)
  else {
    let slotToDelete = itemsToBuy.value.findindex(@(v) v == item) != null
      ? itemsToBuy.value.findindex(@(v) v == item)
        : curItemPart in itemsToBuy.value
      ? curItemPart
        : null
    if (slotToDelete != null)
      itemsToBuy.mutate(@(v) delete v[slotToDelete])
  }
}

let multipleItemsToApply = Computed(function(){
  let { armyId = null } = customizedSoldierInfo.value
  let curItemPart = currentItemPart.value
  let outfitToApply = {}
  if (armyId == null || curItemPart == "")
    return outfitToApply

  let itemToSave = customizationToApply.value?[curItemPart]
  if (itemToSave == null)
    return outfitToApply

  let soldierGuids = soldiersList.value.reduce(@(res, val) res.append(val.guid), [])
  let itemTypes = outfitShopTypes.value

  foreach (sGuid in soldierGuids){
    outfitToApply[sGuid] <- { items = {}, price = {} }
    local itemPrice = {}
    if (itemToSave not in freeItemsBySquad.value[sGuid]){
      let { itemsubtype = null } = findItemTemplate(allItemTemplates, armyId, itemToSave)
      itemPrice = itemTypes?[itemsubtype] ?? {}
    }
    outfitToApply[sGuid].items[curItemPart] <- itemToSave
    outfitToApply[sGuid].price <- itemPrice
  }

  return outfitToApply
})

let multipleItemsToBuy = Computed(function(){
  let multiItemsToBuy = multipleItemsToApply.value.reduce(@(res, soldier)
    soldier.price.len() >= 1 ? res.extend(soldier.items.values()) : res, []) //warning disable: -unwanted-modification
  return multiItemsToBuy
})

let totalItemsCost = Computed(function(){
  let itemsToCheckPrice = customizationToApply.value
  local totalPrice = {}
  if (itemsToCheckPrice.len() <= 0)
    return totalPrice

  let { armyId = null, guid = null} = customizedSoldierInfo.value
  if (armyId == null || guid == null)
    return totalPrice

  foreach (item in itemsToCheckPrice){
    if (itemsToBuy.value.findindex(@(val) val == item) == null)
      continue
    let curItemPrice = curSoldierItemsPrice.value?[item] ?? {}
    curItemPrice.each(function(v){
      let { currencyId = "", orderTpl = "" } = v
      let key = currencyId != "" ? currencyId : orderTpl
      totalPrice[key] <- (totalPrice?[key] ?? 0) + v.price
    })
  }

  return totalPrice
})

let multipleItemsCost = Computed(function(){
  let multiplePurchase = multipleItemsToApply.value
  local totalPrice = {}

  foreach (sItems in multiplePurchase){
    sItems.price.each(function(v){
      let { currencyId = "", orderTpl = "" } = v
      let key = currencyId != "" ? currencyId : orderTpl
      totalPrice[key] <- (totalPrice?[key] ?? 0) + v.price
    })
  }
  return totalPrice
})


let lookCustomizationParts = [
  {
    locId = "appearance/helmet"
    slotName = "helmet"
  },
  {
    locId = "appearance/head"
    slotName = "head"
  },
  {
    locId = "appearance/tunic"
    slotName = "tunic"
  },
  {
    locId = "appearance/gloves"
    slotName = "gloves"
  },
  {
    locId = "appearance/pants"
    slotName = "pants"
  }]

let availableCItem = Computed(function(){
  let res = []
  let { armyId = null, squadId = null, guid = null } = customizedSoldierInfo.value
  if (armyId == null || squadId == null || guid == null)
    return res

  let itemScheme = getCustomizeScheme(squadsCfgById.value, outfitSchemes.value, armyId, squadId)
  local curSoldierItems = clone soldiersLook.value?[guid].items
  let premiumToOverride = allOutfitByArmy.value?[armyId] ?? []
  foreach (item in premiumToOverride)
    if (guid in item.links){
      let slot = item.links[guid]
      curSoldierItems = curSoldierItems.__merge({ [slot] = item.basetpl })
    }

  let templates = {}
  foreach (part in lookCustomizationParts){
    let { slotName } = part
    if (itemScheme?[slotName] == null || itemScheme[slotName].len() == 1)
      continue

    let iconAttachments = []
    let lookItem = customizationToApply.value?[slotName] ?? curSoldierItems?[slotName]
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, lookItem)?.gametemplate ?? ""
    let slotTemplates = findItemTemplate(allItemTemplates, armyId, lookItem)?.slotTemplates ?? {}
    if (slotTemplates.len() > 0)
      foreach (key, val in slotTemplates){
        if (val == "")
          continue
        local templ = templates?[val]
        if (templ == null) {
          templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(val)
          templates[val] <- templ
        }
        if (templ == null) {
          logerr($"Not found look template for {val} at {key} slot")
          continue
        }
        iconAttachments.append({
          animchar = templ.getCompValNullable("animchar__res") ?? ""
          slot = key
          active = templ.getCompValNullable("isActivated") ?? ""
        })
      }
    let allAvailableTemplates = []
    foreach (item in itemScheme[slotName]){
      let template = findItemTemplate(allItemTemplates, armyId, item)?.gametemplate ?? ""
      if (template != "")
        allAvailableTemplates.append(template)
    }
    res.append({
      item = lookItem
      itemTemplate
      iconAttachments
    }.__update(part))
  }
  return res
})


let itemsPerSlot = Computed(function(){
  let { armyId = null, squadId = null, guid = null } = customizedSoldierInfo.value
  let defaultItems = soldiersLook.value?[guid].items
  if (defaultItems == null || armyId == null || squadId == null || guid == null)
    return []

  let itemTypes = outfitShopTypes.value
  let curItemPart = currentItemPart.value
  let allItems = getCustomizeScheme(squadsCfgById.value, outfitSchemes.value, armyId, squadId)
  local res = clone (allItems?[curItemPart] ?? [])
  let curPrice = curSoldierItemsPrice.value
  res = res
    .filter(function(val){
      let { itemsubtype = null } = findItemTemplate(allItemTemplates, armyId, val)
      let curItemPrice = itemTypes?[itemsubtype] ?? {}
      let isItemDefault = defaultItems.findvalue(@(v) v == val) != null
      if (!isItemDefault && curItemPrice.len() <= 0)
        return false
      let isHidden = curItemPrice.findvalue(@(val) val?.isZeroHidden) != null
      if (!isHidden || val in freeItemsBySquad.value[guid])
        return true
      return val in curSoldierItemsPrice.value
    })
    .sort(@(a,b) b in freeItemsBySquad.value[guid] <=> a in freeItemsBySquad.value[guid]
      || (curPrice?[a].len() ?? 0) > 0 <=> (curPrice?[b].len() ?? 0) > 0)
  return res
})

let itemsInfo = Computed(function(){
  let { armyId = null, squadId = null } = customizedSoldierInfo.value
  if (armyId == null || squadId == null)
    return {}

  let allItems = getCustomizeScheme(squadsCfgById.value, outfitSchemes.value, armyId, squadId)
  let templates = {}
  let DB = ecs.g_entity_mgr.getTemplateDB()

  let result = allItems.reduce(function(res, itemsBySlots){
    itemsBySlots.each(function(item){
      if (item == "")
        return
      let { gametemplate = "", slotTemplates = {} } = findItemTemplate(allItemTemplates, armyId, item)
      let iconAttachments = []
      foreach (key, val in slotTemplates){
        if (val == "")
          continue
        local templ = templates?[val]
        if (templ == null){
          templ = DB.getTemplateByName(val)
          templates[val] <- templ
        }
        if (templ == null) {
          if (DB.size() != 0)
            logerr($"Not found items template for {val} at {key} slot")
          continue
        }
        iconAttachments.append({
          animchar = templ.getCompValNullable("animchar__res") ?? ""
          slot = key
          active = templ.getCompValNullable("isActivated") ?? ""
        })
      }
      res[item] <- { gametemplate, iconAttachments }
    })
    return res
  }, {})
  return result
})

let function getItemsToBuy(){
  let items = (isMultiplePurchasing.value ? multipleItemsToBuy.value : itemsToBuy.value)
  .reduce(function(res, tpl) {
    res[tpl] <- (res?[tpl] ?? 0) + 1
    return res
  }, {})
  return items
}

let function buyItemsWithCurrency(){
  let { armyId = null } = customizedSoldierInfo.value
  if (armyId == null || isPurchasing.value)
    return

  let price = isMultiplePurchasing.value
    ? multipleItemsCost.value.EnlistedGold
    : totalItemsCost.value.EnlistedGold
  let items = getItemsToBuy()
  return purchaseMsgBox({
    price
    currencyId = "EnlistedGold"
    alwaysShowCancel = true
    purchase = function(){
      isPurchasing(true)
      buy_outfit(armyId, items, price, @(_) isPurchasing(false))
    }
  })
}

let function buyItemsWithTickets() {
  let { armyId = null } = customizedSoldierInfo.value
  if (armyId == null || isPurchasing.value)
    return

  let orderTpl = isMultiplePurchasing.value
    ? multipleItemsCost.value.findindex(@(_, id) id != "EnlistedGold")
    : totalItemsCost.value.findindex(@(_, id) id != "EnlistedGold")

  if (orderTpl == null)
    return

  let price = isMultiplePurchasing.value
    ? multipleItemsCost.value[orderTpl]
    : totalItemsCost.value[orderTpl]
  let items = getItemsToBuy()
  let orders = getPayItemsData({ [orderTpl] = price }, curCampItems.value)

  isPurchasing(true)
  use_outfit_orders(armyId, items, orders, @(_) isPurchasing(false))
}

let function closeCustomizationWnd(){
  currentItemPart("")
  curCustomizationItem(null)
  customizationToApply({})
  isCustomizationWndOpened(false)
}

let function saveOutfit(){
  if (customizationToApply.value.len() <= 0) {
    closeCustomizationWnd()
    return
  }

  local hasChanges = false
  foreach (item in customizationToApply.value){
    if (oldSoldiersLook.value.findindex(@(v) v == item) == null){
      hasChanges = true
      break
    }}

  let { guid = null } = customizedSoldierInfo.value
  if (!hasChanges || guid == null) {
    closeCustomizationWnd()
    return
  }

  let free = {}
  let prem = {}
  if (itemsToBuy.value.len() > 0){
    let self = callee()
    showMsgbox({
      text = loc("msg/leaveAppearanceConfirm")
      buttons = [
        { text = loc("Yes"),
          action = function(){
            foreach (slot, item in oldSoldiersLook.value)
              customizationToApply.mutate(@(v) v[slot] <- item)
            itemsToBuy({})
            self()
          },
          isCurrent = true }
        { text = loc("Cancel"), isCancel = true }
      ]
    })
    return
  }
  foreach (slot, outfitTmpl  in customizationToApply.value) {
    if (outfitTmpl == ""){
      free[slot] <- outfitTmpl
      continue
    }
    let premList = curArmyOutfit.value ?? []
    let prems = premList.findvalue(@(val) val.basetpl == outfitTmpl) ?? {}
    if (prems.len() > 0)
      prem[slot] <- prems.guid
    else
      prem[slot] <- ""
  }

  apply_outfit(guid, free, prem)
  closeCustomizationWnd()
}

let function multipleApplyOutfit(){
  let appliedItems = []
  foreach (soldierGuid, sItems in multipleItemsToApply.value)
    foreach (slot, item in sItems.items){
      let multiPrem = {}
      let premList = curArmyOutfit.value ?? []
      let defaultItems = soldiersLook.value?[soldierGuid].items ?? {}
      if (defaultItems.findvalue(@(v) v == item) != null)
        multiPrem[slot] <- ""
      else {
        let prems = premList.findvalue(@(val) val.basetpl == item
          && !appliedItems.contains(val.guid))
        multiPrem[slot] <- prems?.guid
        appliedItems.append(prems?.guid)
      }
      apply_outfit(soldierGuid, {}, multiPrem)
    }
  closeCustomizationWnd()
}

isCustomizationWndOpened.subscribe(function(v){
  if (!v)
    return

  let { armyId = null, guid = null } = customizedSoldierInfo.value
  if (armyId == null || guid == null)
    return

  let res = {}
  foreach (item in availableCItem.value)
    res.__update({ [item.slotName] = item.item} )

  let premiumToOverride = allOutfitByArmy.value?[armyId] ?? []
  foreach (item in premiumToOverride)
    if (guid in item.links)
      res.__update({ [item.links[guid]] = item.basetpl })
  oldSoldiersLook(res)
  curCustomizationItem(oldSoldiersLook.value?[currentItemPart.value])
  customizationToApply.mutate(@(v) v[currentItemPart.value] <- curCustomizationItem.value)
})

curArmyOutfit.subscribe(function(v){
  if (v == null)
    return
  foreach (item in v)
    checkIfCanBuy(item.basetpl)
})

let function removeItem(itemToDelete){
  let key = itemsToBuy.value.findindex(@(v) v == itemToDelete)
  if (key != null){
    itemsToBuy.mutate(@(v) delete v[key])
    customizationToApply.mutate(@(v) delete v[key])
    if (itemsToBuy.value.len() <= 0){
      curCustomizationItem(oldSoldiersLook.value?[currentItemPart.value])
      closePurchaseWnd()
    }
  }
}


let function removeAndCloseWnd(itemToDelete){
  removeItem(itemToDelete)
  curCustomizationItem(null)
  closePurchaseWnd()
}

local function blockOnClick(slotName){
  currentItemPart(slotName)
  isCustomizationWndOpened(true)
}

local function itemBlockOnClick(item){
  curCustomizationItem(item)
  customizationToApply.mutate(@(v) v[currentItemPart.value] <- item)
  checkIfCanBuy(item)
}

console_register_command(function() {
  if (customizedSoldierInfo.value == null) {
    console_print("Please select soldier for customization")
    return
  }

  let { guid, armyId, squadId } = customizedSoldierInfo.value
  let premList = curArmyOutfit.value ?? []
  let outfitTypes = outfitShopTypes.value
  let scheme = getCustomizeScheme(squadsCfgById.value, outfitSchemes.value, armyId, squadId)
  let free = {}
  let prem = {}
  foreach (slotId, list in scheme) {
    let freeAvail = []
    let premAvail = []
    foreach (outfitTmpl in list) {
      if (outfitTmpl == "")
        freeAvail.append(outfitTmpl)
      else {
        let prems = premList
          .filter(@(outfit) outfit.basetpl == outfitTmpl)
          .map(@(outfit) outfit.guid)
        if (prems.len() > 0)
          premAvail.extend(prems)
        else {
          let { itemsubtype = "" } = findItemTemplate(allItemTemplates, armyId, outfitTmpl)
          if (itemsubtype not in outfitTypes)
            freeAvail.append(outfitTmpl)
        }
      }
    }
    if (freeAvail.len() > 0)
      free[slotId] <- freeAvail[rand.rint(0, freeAvail.len() - 1)]
    if (premAvail.len() > 0)
      prem[slotId] <- premAvail[rand.rint(0, premAvail.len() - 1)]
  }
  apply_outfit(guid, free, prem, console_print)
}, "outfit.applyRandom")

return {
  lookCustomizationParts
  availableCItem
  isCustomizationWndOpened
  currentItemPart
  itemsPerSlot
  curCustomizationItem
  blockOnClick
  customizationToApply
  itemBlockOnClick
  outfitShopTypes
  totalItemsCost
  APPEARANCE_ORDER_TPL
  removeItem
  buyItemsWithCurrency
  buyItemsWithTickets
  PURCHASE_WND_UID
  removeAndCloseWnd
  closePurchaseWnd
  isPurchasing
  itemsToBuy
  saveOutfit
  premiumItemsCount
  oldSoldiersLook
  curSoldierItemsPrice
  customizationItems
  itemsInfo
  allOutfitByArmy
  multipleItemsCost
  multipleItemsToBuy
  isMultiplePurchasing
  multipleApplyOutfit
}