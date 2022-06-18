from "%enlSqGlob/ui_library.nut" import *

let { purchaseUserLogs, userLogRows } = require("userLogState.nut")
let { mkPurchaseLog, borderColor } = require("userLogPkg.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")


let selectedIdx = Watched(0)

return function() {
  let sItems = shopItems.value
  let allTpl = allItemTemplates.value
  let selIdx = selectedIdx.value
  return {
    watch = [purchaseUserLogs, userLogRows, shopItems, selectedIdx]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = purchaseUserLogs.value.map(function(uLog, idx) {
      let shopItem = sItems?[uLog.shopItemId]
      let uLogRows = selIdx != idx ? null
        : userLogRows.value?[uLog.guid] ?? []

      return shopItem == null ? null
        : watchElemState(@(sf) {
            rendObj = ROBJ_BOX
            size = [flex(), SIZE_TO_CONTENT]
            behavior = Behaviors.Button
            onClick = @() selectedIdx(idx)
            borderColor = borderColor(sf, uLogRows != null)
            borderWidth = hdpx(1)
            children = mkPurchaseLog(uLog, uLogRows, shopItem, allTpl)
          })
    })
  }
}
