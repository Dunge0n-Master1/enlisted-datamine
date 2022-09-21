from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let {bigPadding, unitSize, slotBaseSize, listCtors, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { bgColor, txtColor } = listCtors
let {gray} = require("%ui/components/std.nut")
let dtxt = require("%ui/components/text.nut").dtext
let { mkItem } = require("%enlist/soldiers/components/itemComp.nut")
let mkSoldierCard = require("%enlSqGlob/ui/mkSoldierCard.nut")
let { calc_golden_ratio_columns } = require("%sqstd/math.nut")
let { mkXpBooster, mkBoosterInfo, mkBoosterLimits, boosterWidthToHeight
} = require("%enlist/components/mkXpBooster.nut")
let { rewardBgSizePx } = require("%enlist/items/itemsPresentation.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")


let itemSizeShort = [3.4 * unitSize, 1.8 * unitSize]
let itemSizeLong = [6.0 * unitSize, 1.8 * unitSize]
let boosterHeight = (rewardBgSizePx[1] * 0.7).tointeger()
let itemSizeBooster = [(boosterWidthToHeight * boosterHeight).tointeger(), boosterHeight]
let itemSizeByTypeMap = {
  soldier = slotBaseSize
  sideweapon = itemSizeShort
  grenade = itemSizeShort
  scope = itemSizeShort
  knife = itemSizeShort
  repair_kit = itemSizeShort
  medkits = itemSizeShort
  melee = itemSizeShort
  booster = itemSizeBooster
}

local animDelay = 0
local trigger = ""
let getItemSize = @(itemType) itemSizeByTypeMap?[itemType] ?? itemSizeLong
let minColumns = 2

let TITLE_DELAY = 0.5
let ITEM_DELAY = 0.3
let ADD_OBJ_DELAY = 0.5
let SKIP_ANIM_POSTFIX = "_skip"


let dropTitle = @(titleText) {
  size = SIZE_TO_CONTENT
  margin = [bigPadding, 0]
  transform = {}
  animations = [
    { prop = AnimProp.opacity,   from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic}
    { prop = AnimProp.scale,     from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic}
    { prop = AnimProp.translate, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.3, play = true, easing = OutQuart}
    { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
  ]
  children = dtxt(titleText, {
    size = SIZE_TO_CONTENT
  }.__update(h2_txt))
}

let function blockTitle(blockId, params) {
  animDelay += TITLE_DELAY

  return {
    transform = {}
    animations = params.hasAnim ? [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.8,
        play = true, easing = OutQuart, trigger = trigger }
      { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
    ] : []
    children = dtxt(loc($"received/{blockId}"), {
      size = SIZE_TO_CONTENT
      hplace = ALIGN_LEFT
      color = gray
    }.__update(body_txt))
  }
}

let mkItemByTypeMap = {
  soldier = function(p){
    let group = ElemGroup()
    let soldierInfo = p.item
    let stateFlags = Watched(0)
    return @() {
      watch = [stateFlags, needFreemiumStatus, perkLevelsGrid]
      group = group
      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags(sf)
      onClick = p.onClickCb

      children = mkSoldierCard({
        soldierInfo = soldierInfo
        squadInfo = squadsCfgById.value?[soldierInfo?.armyId ?? ""][soldierInfo?.squadId ?? ""]
        expToLevel = perkLevelsGrid.value?.expToLevel
        size = itemSizeLong
        group = group
        sf = stateFlags.value
        isDisarmed = p?.isDisarmed
        isFreemiumMode = needFreemiumStatus.value
      })
    }
  }

  booster = function(p) {
    let { item, onClickCb } = p
    let stateFlags = Watched(0)
    return function() {
      let sf = stateFlags.value
      let textColor = txtColor(sf, false)
      let { count = 1 } = item
      return {
        watch = stateFlags
        rendObj = ROBJ_SOLID
        size = itemSizeBooster
        behavior = Behaviors.Button
        onElemState = @(s) stateFlags(s)
        onClick = onClickCb
        color = bgColor(sf, false)
        children = [
          mkXpBooster(item)
          {
            size = flex()
            padding = smallPadding
            children = [
              mkBoosterInfo(item, sub_txt.__merge({ color = textColor }))
              mkBoosterLimits(item, sub_txt.__merge({ color = textColor }))
              count <= 1 ? null
               : {
                    rendObj = ROBJ_TEXT
                    hplace = ALIGN_RIGHT
                    text = loc("common/amountShort", item)
                    color = textColor
                  }.__update(sub_txt)
            ]
          }
        ]
      }
    }
  }
}

let function mkItemExt(item, params) {
  let ctor = mkItemByTypeMap?[item?.itemtype]
  let ctorAddParams = ctor == null ? {}
    : { isDisarmed = params?.isDisarmed }
  animDelay += ITEM_DELAY
  return {
    transform = {}
    key = item?.guid ?? item
    animations = params.hasAnim ? [
      { prop = AnimProp.opacity,                      from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, trigger = trigger, onFinish = params.onVisibleCb}
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.5,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.5,
        play = true, easing = OutCubic, trigger = trigger }
    ] : []

    children = (ctor ?? mkItem)({
      item = item
      onClickCb = params?.onItemClick ? @(...) params.onItemClick(item) : null
      itemSize = getItemSize(item?.itemtype)
      canDrag = false
      isInteractive = params?.onItemClick ? true : false
      pauseTooltip = params?.pauseTooltip ?? Watched(false)
    }.__update(ctorAddParams))
  }
}

let function blockContent(items, columnsAmount, params) {
  let itemSize = getItemSize(items?[0].itemtype)
  let containerWidth = columnsAmount * itemSize[0] + (columnsAmount - 1) * bigPadding
  return {
    flow = FLOW_HORIZONTAL
    children = wrap (items.map(@(item) mkItemExt(item, params)), {
      width = containerWidth
      hGap = bigPadding
      vGap = bigPadding
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
    })
  }
}

let function itemsBlock(items, blockId, params) {
  if (!items.len())
    return null

  let itemSize = getItemSize(items?[0].itemtype)
  let columnsAmount = params.width != null
    ? ((params.width - (params.width / itemSize[0] - 1).tointeger() * bigPadding) / itemSize[0]).tointeger()
    : max(minColumns, calc_golden_ratio_columns(items.len(), itemSize[0] / itemSize[1]))

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigPadding

    children = (blockId ? [blockTitle(blockId, params)] : [])
      .append(blockContent(items, columnsAmount, params))
  }
}

let function appearAnim(comp, hasAnim) {
  animDelay += ADD_OBJ_DELAY
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = comp

    animations = hasAnim ? [
      { prop = AnimProp.opacity,                    from = 0, to = 0, duration = animDelay,
        play = true, trigger = trigger + SKIP_ANIM_POSTFIX }
      { prop = AnimProp.opacity, delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }
}

let ITEMS_REWARDS_PARAMS = {
  hasAnim = true
  titleText = ""
  addChildren = []
  baseAnimDelay = 0.0
  hasItemTypeTitle = true
  animTrigger = "mkAnimatedItems"
  onVisibleCb = null
  width = null
  onItemClick = null
}

local function mkAnimatedItemsBlock(itemBlocks, params = ITEMS_REWARDS_PARAMS) {
  params = ITEMS_REWARDS_PARAMS.__merge(params)
  animDelay = params.baseAnimDelay
  trigger = params.animTrigger
  let underline = {
    rendObj = ROBJ_FRAME
    size = [pw(80), 1]
    margin = bigPadding
    borderWidth = [0, 0, 1, 0]
    color = Color(100, 100, 100, 50)
    transform = {}
    animations = params.hasAnim ? [
      { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.2,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale, delay = 0.2 from = [0, 1], to = [1, 1], duration = 1,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }

  let blocks = itemBlocks.keys()

  let children = []
  if (params.titleText.len())
    children.append(
      dropTitle(params.titleText)
      underline
    )
  else
    animDelay -= TITLE_DELAY

  children.append({
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = blocks.map(@(blockId) itemsBlock(itemBlocks[blockId], params.hasItemTypeTitle ? blockId : null, params))
  })

  children.extend(params.addChildren.map(@(comp) appearAnim(comp, params.hasAnim)))

  return {
    totalTime = params.hasAnim ? animDelay : 0
    component = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = children
    }
  }
}

return mkAnimatedItemsBlock
