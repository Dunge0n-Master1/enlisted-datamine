from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { soldiersLook } = require("%enlist/meta/servProfile.nut")
let { outfitSchemes, outfitShopTypes, curArmyOutfit, allOutfitByArmy
} = require("%enlist/soldiers/model/config/outfitConfig.nut")
let { findItemTemplate, allItemTemplates
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { appearanceToRender } = require("%enlist/scene/soldier_tools.nut")
let { curSoldierInfo } = require("model/squadInfoState.nut")
let { apply_outfit, buy_outfit, use_outfit_orders } = require("%enlist/meta/clientApi.nut")
let rand = require("%sqstd/rand.nut")()
let { removeModalWindow } = require("%darg/components/modalWindows.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { isFreemiumCampaign } = require("%enlist/campaigns/freemiumState.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { isLinkedTo } = require("%enlSqGlob/ui/metalink.nut")
let { logerr } = require("dagor.debug")

let isCustomizationWndOpened = Watched(false)
let isPurchasing = Watched(false)
let currentItemPart = mkWatched(persist, "currentItemPart", "")
let curCustomizationItem = mkWatched(persist, "curCustomizationItem", null)
let customizationToApply = mkWatched(persist, "customizationToApply", {})
let itemsToBuy = mkWatched(persist, "itemsToBuy", {})
let oldSoldiersLook = mkWatched(persist, "oldSoldiersLook", {})
const APPEARANCE_ORDER_TPL = "appearance_change_order"
const PURCHASE_WND_UID = "PURCHASE_WND"

// simple freemium logic right now; flag can be moved to campaigns setup in future
let isCustomizationAvailable = Computed(@() isFreemiumCampaign.value)

currentItemPart.subscribe(@(v)
  curCustomizationItem(customizationToApply.value?[v]))

let customizationItems = Computed(@()
  customizationToApply.value.reduce(@(res, v) res.rawset(v, true), {}))

let closePurchaseWnd = @() removeModalWindow(PURCHASE_WND_UID)
isPurchasing.subscribe(@(v) v ? null : closePurchaseWnd())

customizationToApply.subscribe(function(v){
  if(curSoldierInfo.value == null || v.len() <= 0){
    gui_scene.setTimeout(0.1, @() appearanceToRender(null))
    return
  }
  appearanceToRender(v)
})

let curSoldierItemsPrice = Computed(function(){
  let { armyId = null, squadId = null, guid = null } = curSoldierInfo.value
  let res = {}
  if (armyId == null || squadId == null || guid == null)
    return res

  let defaultItems = soldiersLook.value?[guid].items ?? {}
  let defaultItemsTbl = defaultItems.reduce(@(res, val) res.rawset(val, true), {})
  let linkedItems = allOutfitByArmy.value?[armyId] ?? []
  let linkedItemsTbl = linkedItems.reduce(@(res, val) res.rawset(val.basetpl, val), {})
  let itemTypes = outfitShopTypes.value
  let allItems = outfitSchemes.value?[armyId][squadId] ?? {}
  let curArmyOutfitTbl = curArmyOutfit.value.reduce(@(res, val) res.rawset(val.basetpl, true), {})

  allItems.each(@(val) val.each(function(item){
    let isItemLinked = item in linkedItemsTbl
      && (isLinkedTo(linkedItemsTbl[item], guid) || item in curArmyOutfitTbl)
    if (item in defaultItemsTbl || isItemLinked)
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
  let { armyId = null, guid = null} = curSoldierInfo.value
  if(armyId == null || guid == null)
    return res

  let linkedItems = allOutfitByArmy.value?[armyId] ?? []
  foreach(item in linkedItems)
    if(item.links.len() == 1 || guid in item.links)
      res[item.basetpl] <- (res?[item.basetpl] ?? 0) + 1

  return res
})


let function checkIfCanBuy(item){
  let { armyId = null, guid = null } = curSoldierInfo.value
  let curItemPart = currentItemPart.value
  if(armyId == null || guid == null || curItemPart == null)
    return

  let hasPrice = curSoldierItemsPrice.value?[item] != null
  let linkedItems = allOutfitByArmy.value?[armyId] ?? []
  if(hasPrice && linkedItems.findvalue(@(val) val.basetpl == item
    && (guid in val.links || val.links.len() <= 1)) == null)
      itemsToBuy.mutate(@(v) v[curItemPart] <- item)
  else {
    let slotToDelete = itemsToBuy.value.findindex(@(v) v == item) != null
      ? itemsToBuy.value.findindex(@(v) v == item)
        : curItemPart in itemsToBuy.value
      ? curItemPart
        : null
    if(slotToDelete != null)
      itemsToBuy.mutate(@(v) delete v[slotToDelete])
  }
}

let totalItemsCost = Computed(function(){
  let itemsToCheckPrice = customizationToApply.value
  local totalPrice = {}

  if(itemsToCheckPrice.len() <= 0)
    return totalPrice
  let { armyId = null, guid = null} = curSoldierInfo.value
  if(armyId == null || guid == null)
    return totalPrice
  foreach(item in itemsToCheckPrice){
    if(itemsToBuy.value.findindex(@(val) val == item) == null)
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

let lookCustomizationParts = [
  {
    locId = "appearance/helmet"
    slotName = "helmet"
    hideIfUnchangeable = false
  },
  {
    locId = "appearance/head"
    slotName = "head"
    hideIfUnchangeable = false
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
  if(curSoldierInfo.value == null)
    return res

  let {armyId, squadId, guid} = curSoldierInfo.value
  let itemScheme = outfitSchemes.value?[armyId][squadId]
  local curSoldierItems = clone soldiersLook.value?[guid].items
  let premiumToOverride = allOutfitByArmy.value?[armyId] ?? []
  foreach(item in premiumToOverride)
    if(guid in item.links){
      let slot = item.links[guid]
      curSoldierItems = curSoldierItems.__merge({ [slot] = item.basetpl })
    }

  let templates = {}
  foreach(part in lookCustomizationParts){
    let partItem = part.slotName

    if(itemScheme?[partItem] == null || (part?.hideIfUnchangeable ?? false))
        continue
    let iconAttachments = []
    let lookItem = customizationToApply.value?[partItem] ?? curSoldierItems?[partItem]
    let itemTemplate = findItemTemplate(allItemTemplates, armyId, lookItem)?.gametemplate ?? ""
    let slotTemplates = findItemTemplate(allItemTemplates, armyId, lookItem)?.slotTemplates ?? {}
    if(slotTemplates.len() > 0)
      foreach(key, val in slotTemplates){
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
    foreach(item in (itemScheme?[part.slotName] ?? [])){
      let template = findItemTemplate(allItemTemplates, armyId, item)?.gametemplate ?? ""
      if(template != "")
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
  if(curSoldierInfo.value == null)
    return []

  let { armyId, squadId, guid } = curSoldierInfo.value
  let defaultItems = soldiersLook.value?[guid].items
  if(defaultItems == null)
    return []

  let itemTypes = outfitShopTypes.value
  let curItemPart = currentItemPart.value
  let allItems = outfitSchemes.value?[armyId][squadId]
  local res = clone (allItems?[curItemPart] ?? [])
  let items = defaultItems.reduce(@(res, val) res.rawset([val], true), {})
  let curPrice = curSoldierItemsPrice.value
  res = res
    .filter(function(val){
      let { itemsubtype = null } = findItemTemplate(allItemTemplates, armyId, val)
      let curItemPrice = itemTypes?[itemsubtype] ?? {}
      let isHidden = curItemPrice.findvalue(@(val) val?.isZeroHidden) != null
      if (!isHidden || defaultItems.findvalue(@(items) val == items) != null)
        return true
      return val in curSoldierItemsPrice.value
    })
    .sort(@(a,b) b in items <=> a in items
      || (curPrice?[a].len() ?? 0) > 0 <=> (curPrice?[b].len() ?? 0) > 0)
  return res
})

let itemsInfo = Computed(function(){
  let { armyId = null, squadId = null } = curSoldierInfo.value
  local result = {}
  if (armyId == null || squadId == null)
    return result

  let allItems = outfitSchemes.value?[armyId][squadId] ?? {}
  let templates = {}
  result = allItems.reduce(function(res, itemsBySlots){
    itemsBySlots.each(function(item){
      let { gametemplate = "", slotTemplates = {} } = findItemTemplate(allItemTemplates, armyId, item)
      let iconAttachments = []
      foreach(key, val in slotTemplates){
        local templ = templates?[val]
        if (templ == null){
          templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(val)
          templates[val] <- templ
        }
        if (templ == null) {
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


let function buyItemsWithCurrency(){
  let { armyId = null } = curSoldierInfo.value
  if(armyId == null || isPurchasing.value)
    return

  let price = totalItemsCost.value.EnlistedGold
  let items = itemsToBuy.value.reduce(function(res, tpl) {
    res[tpl] <- 1
    return res
  }, {})

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
  let { armyId = null } = curSoldierInfo.value
  if(armyId == null || isPurchasing.value)
    return

  let orderTpl = totalItemsCost.value.findindex(@(_, id) id != "EnlistedGold")
  if (orderTpl == null)
    return

  let price = totalItemsCost.value[orderTpl]
  let items = itemsToBuy.value.reduce(function(res, tpl) {
    res[tpl] <- 1
    return res
  }, {})
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
  if (customizationToApply.value.len() <= 0)
    return closeCustomizationWnd()

  local hasChanges = false
  foreach(item in customizationToApply.value){
    if(oldSoldiersLook.value.findindex(@(v) v == item) == null){
      hasChanges = true
      break
    }}

  if(!hasChanges)
    return closeCustomizationWnd()

  let { guid } = curSoldierInfo.value
  let free = {}
  let prem = {}
  if(itemsToBuy.value.len() > 0){
    let self = callee()
    showMsgbox({
      text = loc("msg/leaveAppearanceConfirm")
      buttons = [
        { text = loc("Yes"),
          action = function(){
            foreach(slot, item in oldSoldiersLook.value)
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
  foreach(slot, outfitTmpl  in customizationToApply.value) {
    if(outfitTmpl == ""){
      free[slot] <- outfitTmpl
      continue
    }
    let premList = curArmyOutfit.value ?? []
    let prems = premList.findvalue(@(val) val.basetpl == outfitTmpl) ?? {}
    if(prems.len() > 0)
      prem[slot] <- prems.guid
    else
      prem[slot] <- ""
  }

  apply_outfit(guid, free, prem)
  closeCustomizationWnd()
}

isCustomizationWndOpened.subscribe(function(v){
  if(v){
    let { armyId, guid } = curSoldierInfo.value
    if(armyId == null || guid == null)
      return
    let res = {}
    foreach(item in availableCItem.value)
      res.__update({ [item.slotName] = item.item} )

    let premiumToOverride = allOutfitByArmy.value?[armyId] ?? []
    foreach(item in premiumToOverride)
      if(guid in item.links)
        res.__update({ [item.links[guid]] = item.basetpl })
    oldSoldiersLook(res)
    curCustomizationItem(oldSoldiersLook.value?[currentItemPart.value])
  }
})

curArmyOutfit.subscribe(function(v){
  if(v == null)
    return
  foreach(item in v)
    checkIfCanBuy(item.basetpl)
})

let function removeItem(itemToDelete){
  let key = itemsToBuy.value.findindex(@(v) v == itemToDelete)
  if (key != null){
    itemsToBuy.mutate(@(v) delete v[key])
    customizationToApply.mutate(@(v) delete v[key])
    if(itemsToBuy.value.len() <= 0){
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
  if (curSoldierInfo.value == null) {
    console_print("Please select soldier for customization")
    return
  }

  let { guid, armyId, squadId } = curSoldierInfo.value
  let premList = curArmyOutfit.value ?? []
  let outfitTypes = outfitShopTypes.value
  let scheme = outfitSchemes.value?[armyId][squadId] ?? {}
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
  curArmyOutfit
  saveOutfit
  isCustomizationAvailable
  premiumItemsCount
  oldSoldiersLook
  curSoldierItemsPrice
  customizationItems
  itemsInfo
}