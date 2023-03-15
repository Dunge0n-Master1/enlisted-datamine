from "%enlSqGlob/ui_library.nut" import *

let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let colorize = require("%ui/components/colorize.nut")
let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let spinner = require("%ui/components/spinner.nut")({ opacity = 0.7 })
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { utf8ToLower } = require("%sqstd/string.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { commonArmy } = require("%enlist/meta/profile.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { doesLocTextExist } = require("dagor.localize")
let { bigPadding, activeTxtColor, soldierLvlColor } = require("%enlSqGlob/ui/viewConst.nut")
let { itemWeights, mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let { getItemName, trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  kindIcon, className, classIcon
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { isLootBoxProhibited } = require("%enlist/meta/metaConfigUpdater.nut")


let mkTextArea = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  color = activeTxtColor
  text = text
}

let mkItemRow = @(item) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(5)
  children = [
    itemTypeIcon(item?.itemtype, item?.itemsubtype)
    txt(getItemName(item))
  ]
}

let getExpBoost = @(item) item?.expMul ?? item?.tpl.expMul ?? 0.0
let getTierTo = @(item) item?.tierTo ?? item?.tpl.tierTo ?? 0
let getItemtype = @(item) item?.itemtype ?? item?.tpl.itemtype ?? 0
let getWeights = @(item) itemWeights?[getItemtype(item)] ?? 0
let getWorth = @(item) item?.worth ?? 0
let getCount = @(item) item?.count ?? 0
let getBasetpl = @(item) item?.basetpl ?? item?.gametemplate
  ?? item?.tpl.basetpl ?? item?.tpl.gametemplate ?? 0

let itemsSort = @(a, b)
  getWeights(a) <=> getWeights(b)
    || getWorth(a) <=> getWorth(b)
    || getTierTo(b) <=> getTierTo(a)
    || getExpBoost(a) <=> getExpBoost(b)
    || getCount(a) <=> getCount(b)
    || getBasetpl(a) <=> getBasetpl(b)

let mkItemsListWithHeader = @(itemTpls, armyId, header = null) function() {
  let templates = allItemTemplates.value
  let armyTemplates = templates?[armyId]
  let commonTemplates = templates?[commonArmy.value]
  return {
    watch = [commonArmy, allItemTemplates]
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = (header == null ? [] : [mkTextArea(header)])
      .append({
        flow = FLOW_VERTICAL
        children = itemTpls
          .map(function(tplId) {
            let tpl = armyTemplates?[tplId] ?? commonTemplates?[tplId]
            return tpl == null ? null : mkShopItem(tplId, tpl, armyId)
          })
          .filter(@(i) i != null)
          .reduce(function(tbl, item) {
            let tplId = trimUpgradeSuffix(item.basetpl)
            let { tier = 0 } = item
            item = tbl?[tplId] ?? item
            item.tierFrom <- min(item?.tierFrom ?? 1000, tier)
            item.tierTo <- max(item?.tierTo ?? 0, tier)
            tbl[tplId] <- item
            return tbl
          }, {})
          .values()
          .sort(itemsSort)
          .map(mkItemRow)
      })
  }
}

local function mkCrateItemsInfo(armyId, content, header = null, addChild = null, isRestrictedItem = false) {
  let { items = null, groupLocId = "" } = content
  if ((items?.len() ?? 0) == 0)
    return null

  if (header == null) {
    let minAmount = content?.itemsAmount.x ?? 1
    let maxAmount = content?.itemsAmount.y ?? 1
    header = minAmount == maxAmount
      ? loc("crateContentHeader", {
          amountText = colorize(soldierLvlColor, minAmount)
          amount = minAmount
        })
      : loc("crateContentHeaderRandItems", {
          amountText = colorize(soldierLvlColor, $"{minAmount} - {maxAmount}")
        })
  }

  local groupedItems = []
  if (typeof items == "array")
    groupedItems.append({ header, items }) // backward compatibility with straight array format
  else if (groupLocId == "")
    groupedItems.append({ header, items = items.keys() })
  else {
    let ungroupedItems = []
    foreach (tplId, idx in items) {
      let locId = $"crategroup/{groupLocId}_{idx}"
      if (!isRestrictedItem && doesLocTextExist(locId)) {
        local data = groupedItems?[idx]
        if (data == null) {
          data = {
            header = loc(locId)
            items = []
          }
          if (groupedItems.len() <= idx)
            groupedItems.resize(idx + 1)
          groupedItems[idx] = data
        }
        data.items.append(tplId)
      } else {
        ungroupedItems.append(tplId)
      }
    }
    if (ungroupedItems.len() > 0)
      groupedItems.append({ header, items = ungroupedItems })
  }
  groupedItems = groupedItems.filter(@(l) l != null)

  let children = []
  foreach (group in groupedItems)
    children.append(mkItemsListWithHeader(group.items, armyId, group.header))
  children.append(addChild)

  return {
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = bigPadding
    children
  }
}

let function mkCrateShuffleInfo(armyId, content) {
  let mainItemsData = (content?.mainItemsData ?? {}).filter(@(d) (d?.shuffleMax ?? 0) > 0)
  if (mainItemsData.len() == 0)
    return null

  let isOpenedOnce = content.openingsCount > 0
  let children = mainItemsData.values()
    .map(@(data) mkCrateItemsInfo(armyId, data, loc("shop/guaranteedContent", data),
      isOpenedOnce
        ? txt({ text = loc("shop/alreadyReceived", data), color = activeTxtColor })
        : null
    ))
    .filter(@(v) v != null)

  if (isOpenedOnce)
    children.append(txt({ text = loc("shop/totalOpened", content), color = activeTxtColor }))

  return children.len() == 0 ? null : {
    gap = bigPadding
    flow = FLOW_VERTICAL
    children
  }
}

let mkSClassRow = @(sClass, armyId) @() {
  watch = sClassesCfg
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(5)
  children = [
    kindIcon(sClassesCfg.value?[sClass].kind ?? sClass, hdpx(22), 0)
    className(sClass)
    classIcon(armyId, sClass, hdpx(22))
  ]
}

let function mkCrateSoldiersInfo(armyId, content) {
  let { soldierClasses = [] } = content
  if (soldierClasses.len() == 0)
    return null

  let sClasses = soldierClasses.map(function(sClass) {
    let locId = getClassCfg(sClass)?.locId ?? ""
    return locId == "" ? null
      : {
          sClass = sClass
          sortLoc = utf8ToLower(loc(locId))
        }
  })
    .filter(@(s) s != null)
    .sort(@(a, b) a.sortLoc <=> b.sortLoc)
    .map(@(s) s.sClass)

  let { soldierTierMin, soldierTierMax, groupLocId = "" } = content
  let tiersText = soldierTierMin == soldierTierMax ? getRomanNumeral(soldierTierMin)
    : $"{getRomanNumeral(soldierTierMin)}-{getRomanNumeral(soldierTierMax)}"
  local locId = $"crategroup/{groupLocId}"
  if (!doesLocTextExist(locId))
    locId = "crateContentSoldiers"

  return {
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      mkTextArea(loc(locId, { tiers = colorize(soldierLvlColor, tiersText) }))
      {
        flow = FLOW_VERTICAL
        children = sClasses.map(@(sClass) mkSClassRow(sClass, armyId))
      }
    ]
  }
}

let function makeCrateToolTip(crateContent, headerTxt = "", size = SIZE_TO_CONTENT) {
  if (crateContent == null)
    return null

  let header = headerTxt == "" ? null : mkTextArea(headerTxt).__update(body_txt)
  return tooltipBox(function() {
    let { armyId = "", content = null } = crateContent.value
    return {
      watch = [crateContent, isLootBoxProhibited]
      gap = bigPadding
      flow = FLOW_VERTICAL
      children = content == null ? spinner
        : [
            header
            mkCrateItemsInfo(armyId, content, null, null, isLootBoxProhibited.value)
            mkCrateShuffleInfo(armyId, content)
            mkCrateSoldiersInfo(armyId, content)
          ]
    }
  }, size)
}

return {
  makeCrateToolTip
  mkItemsListWithHeader
  mkItemRow
  itemsSort
}
