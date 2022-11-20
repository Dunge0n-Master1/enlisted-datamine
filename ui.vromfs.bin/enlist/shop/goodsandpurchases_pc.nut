from "%enlSqGlob/ui_library.nut" import *

let { requestData, createGuidsRequestParams } = require("httpRequest.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let purchases = require("purchases.nut")

let goodsInfo = mkWatched(persist, "goodsInfo", {}) //purchases info from online shop by guids

let isGoodsRequested = Watched(false)
let marketIds = Watched([])
let guidsList = Computed(@() marketIds.value.map(@(val) val.guid))

let function requestGoodsInfo() {
  if (!userInfo.value)
    return

  let guids = guidsList.value.filter(@(guid) guid not in goodsInfo.value)
  if (guids.len() == 0)
    return

  goodsInfo.mutate(function(v) {
    foreach (guid in guids)
      v[guid] <- null
  })

  isGoodsRequested(true)
  requestData(
    "https://api.gaijinent.com/item_info.php",
    createGuidsRequestParams(guids),
    function(data) {
      isGoodsRequested(false)
      let list = data?.items
      if (typeof list != "table" || !list.len())
        return
      goodsInfo.mutate(@(value) value.__update(list))
    },
    function() { isGoodsRequested(false) }
  )
}

userInfo.subscribe(@(_) requestGoodsInfo())
guidsList.subscribe(function(guids) {
  purchases.addGuids(guids)
  requestGoodsInfo()
})

return purchases.__merge({
  goodsInfo
  marketIds
  isGoodsRequested
})