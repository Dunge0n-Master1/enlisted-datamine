from "%enlSqGlob/ui_library.nut" import *

let { purchaseUserLogs, UserLogType } = require("userLogState.nut")
let { mkUserLogHeader, mkRowText, rowStyle, userLogStyle, userLogRowStyle, borderColor
} = require("userLogPkg.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { bigPadding , accentTitleTxtColor, defTxtColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { tierText } = require("%enlSqGlob/ui/soldiersUiComps.nut")


let selectedIdx = Watched(0)


let function mkReceivedItem(row, allTpl) {
  let { armyId, baseTpl, count } = row
  let template = allTpl?[armyId][baseTpl]
  if (template == null)
    return null

  return {
    children = [
      mkRowText(loc("listWithDot", { text = getItemName(template) }), defTxtColor)
      detailsStatusTier(template)
      count <= 1 ? null : mkRowText(loc("common/amountShort", { count }), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

let function mkReceivedSoldier(row, _allTpl = null) {
  let { name, surname, tier, sClass } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = $"{loc(name)} {loc(surname)}" }), defTxtColor)
      tierText(tier)
      mkRowText(loc($"soldierClass/{sClass}"), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

let function mkReceivedPremium(row, _allTpl = null) {
  let { count } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("premium/title") }), defTxtColor)
      mkRowText("{0} {1}".subst(count, loc("premiumDays", { days = count })),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

let function mkReceivedWallposter(row, _allTpl = null) {
  let { wallposterId, armyId } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("userLogRow/wallposter") }), defTxtColor)
      mkRowText("{0} ({1})".subst(loc($"wp/{wallposterId}/name"), loc(armyId)),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

let purchaseRowView = {
  [UserLogType.PURCH_ITEM] = mkReceivedItem,
  [UserLogType.PURCH_SOLDIER] = mkReceivedSoldier,
  [UserLogType.PURCH_PREMDAYS] = mkReceivedPremium,
  [UserLogType.PURCH_WALLPOSTER] = mkReceivedWallposter,
  [UserLogType.PURCH_BONUS] = null
}

let mkPurchaseLogRows = @(uLogRows, allTpl) {
  children = uLogRows.map(@(row) purchaseRowView?[row?.logType](row, allTpl))
}.__update(userLogRowStyle)

let function mkPurchaseLog(uLog, shopItem, allTpl, isSelected) {
  let { nameLocId = "Undefined" } = shopItem
  let shortItemTitle = utf8ToUpper(loc(nameLocId).split("\r\n")?[0] ?? "")
  return {
    children = [
      mkUserLogHeader(isSelected, uLog.logTime,
        loc("userLog/purchase", {
          name = shortItemTitle
        }))
      isSelected && uLog?.rows ? mkPurchaseLogRows(uLog.rows, allTpl) : null
    ]
  }.__update(userLogStyle)
}
let function mkLog(uLog, idx, sItems, allTpl) {
  let shopItem = sItems?[uLog.shopItemId]
  if (shopItem == null)
    return null

  let isSelected = Computed(@() idx == selectedIdx.value)
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    watch = isSelected
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick = @() selectedIdx(idx)
    borderColor = borderColor(sf, isSelected.value)
    borderWidth = hdpx(1)
    children = mkPurchaseLog(uLog, shopItem, allTpl, isSelected.value)
  })
}

return function() {
  let sItems = shopItems.value
  let allTpl = allItemTemplates.value
  return {
    watch = [purchaseUserLogs, shopItems, allItemTemplates]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = purchaseUserLogs.value.map(@(uLog, idx) mkLog(uLog, idx, sItems, allTpl))
  }
}
