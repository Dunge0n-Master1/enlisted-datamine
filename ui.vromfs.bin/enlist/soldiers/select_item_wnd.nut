from "%enlSqGlob/ui_library.nut" import *

let math = require("%sqstd/math.nut")

let { defBgColor, blurBgColor, bigPadding, unitSize, soldierSlotSize } = require("%enlSqGlob/ui/viewConst.nut")

let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { armies, curArmory, curArmy, objInfoByGuid } = require("model/state.nut")

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let itemComp = require("components/itemComp.nut")
let itemsListPkg = require("model/items_list_lib.nut")
let mkSoldier = require("%enlSqGlob/ui/mkSoldierCard.nut")
let { mkSoldiersData } = require("model/collectSoldierData.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")

let itemGap = bigPadding

let DEFAULT_CTOR_DATA = {
  size = [3.0 * unitSize, 2.0 * unitSize]
  ctor = @(item, cb) itemComp.mkItem({item=item, itemSize = [unitSize*3,unitSize*2], onClickCb = cb, canDrag = false})
}

let itemTypeCtorData = {
  soldier = {
    size = soldierSlotSize
    ctor = function(soldier, cb) {
      let stateFlags = Watched(0)
      let soldierData = mkSoldiersData(soldier)
      return @() {
        watch = needFreemiumStatus
        children = mkSoldier({
          soldierInfo = soldierData.value,
          sf=stateFlags.value,
          isFreemiumMode = needFreemiumStatus.value
        }).__update({
            watch = [stateFlags, soldierData]
            key = $"select_{soldier.guid}"
            behavior = Behaviors.Button
            onElemState = @(sf) stateFlags(sf)
            onClick = @(event) cb({item = soldier, rectOrPos = event.targetRect})
          })
      }
    }
  }
}

local function armory(items, callback = null, shopItemsFilter = null){
  items = itemsListPkg.prepareItems(items, objInfoByGuid.value)
  if (shopItemsFilter)
    itemsListPkg.addShopItems(items, curArmy.value, shopItemsFilter)
  items.sort(itemsListPkg.itemsSort)
  let size = (itemTypeCtorData?[items?[0]?.itemtype] ?? DEFAULT_CTOR_DATA).size
  let itemColumns = math.calc_golden_ratio_columns(items.len(), size[0] / size[1])
  let itemContainerWidth = itemColumns*size[0]+(itemColumns-1)*itemGap
  let items_container = wrap(
    items.map(@(item) (itemTypeCtorData?[item?.itemtype] ?? DEFAULT_CTOR_DATA).ctor(item, callback)),
    {width = itemContainerWidth, hGap=bigPadding, vGap=bigPadding, hplace=ALIGN_CENTER}
  )
  return items_container
}

let WINDOW_PARAMS = {
  header = loc("Select")
  onClick = null
  shopItemsFilter = null //@(templateId, template) true. When not null, not owned items will be added to list
  popupParams = {}
}
local function mkSelectItemWindow(items, p = WINDOW_PARAMS){
  p = WINDOW_PARAMS.__merge(p)
  return @() {
    hplace = ALIGN_CENTER
    gap = bigPadding
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    watch = [curArmory, armies]
    children = [txt(p.header), armory(items, p.onClick, p.shopItemsFilter)]
  }
}

return {
  open = @(rectOrPos, items, p = WINDOW_PARAMS) modalPopupWnd.add(rectOrPos, {
    padding = [bigPadding, bigPadding]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = Color(0,0,0,0)
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, color = Color(150,150,150,150) fillColor = defBgColor }
    popupOffset = bigPadding
    popupValign = ALIGN_TOP
    popupFlow = FLOW_HORIZONTAL

    children = mkSelectItemWindow(items, p)
  }.__update(p?.popupParams ?? WINDOW_PARAMS.popupParams))
  close = @(key) modalPopupWnd.remove(key)
}