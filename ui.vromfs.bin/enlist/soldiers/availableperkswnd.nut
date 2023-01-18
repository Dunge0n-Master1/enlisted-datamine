from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let { bigPadding, noteTxtColor, defTxtColor, insideBorderColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { uniteEqualPerks, tierTitle, thumbIconSize, perkCard
} = require("components/perksPackage.nut")
let { getPerkPointsInfo } = require("model/soldierPerks.nut")
let { pPointsList } = require("%enlist/meta/perks/perksPoints.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { RECOMMENDED_PERKS_COUNT } = require("%enlist/meta/perks/perksStats.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")

const WND_UID = "possiblePerksWindow"
let BG_DARKEN = Color(0, 0, 0, 255)

let close = @() removeModalWindow(WND_UID)
let closeButton = closeBtnBase({ onClick = close })

let wndPadding = hdpx(32)

let recommendedPerksHeader = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      text = loc("possible_perks_list")
      color = defTxtColor
    }.__update(body_txt)
    {
      size = [hdpx(420), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      padding = bigPadding
      hplace = ALIGN_RIGHT
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = [thumbIconSize, thumbIconSize]
          image = Picture($"!ui/uiskin/thumb.svg:{thumbIconSize}:{thumbIconSize}:K")
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXT
          color = defTxtColor
          text = loc("recommended_perks_list")
        }.__update(body_txt)
        closeButton
      ]
    }
  ]
}

let wndHeader = @(header){
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = bigPadding
  children = [
    recommendedPerksHeader
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = noteTxtColor
      text = header
    }.__update(sub_txt)
  ]
}

let wndContent = @(content) scrollbar.makeVertScroll(
  {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = content
  }, {
    size = [flex(), SIZE_TO_CONTENT]
    needReservePlace = false
  })

let function open(content, header) {
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    borderColor = insideBorderColor
    fillColor = BG_DARKEN
    uid = "tier_perks_list"
    size = [hdpx(1380), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = wndPadding
    padding = wndPadding
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    children = [
      wndHeader(header)
      wndContent(content)
    ]
  })
}

let function removeOnce(arr, val) {
  let idx = arr.indexof(val)
  if (idx != null)
    arr.remove(idx)
}

let mkPerksList = @(armyId, perks){
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = perks.map(@(perksBlock){
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    children = perksBlock.map(@(perkData, idx) perkCard({
      armyId
      perkData = perkData
      slotNumber = idx
    }))
  })
}

let function splitPerksByType(paramsList, perksListVal, tierPerks, pointsInfo) {
  paramsList.each(function(p) {
    p.totalCost <- 0
    p.isAvailable <- true
    p.costMask <- 0
    let index = tierPerks.indexof(p.perkId) ?? RECOMMENDED_PERKS_COUNT
    if (index < RECOMMENDED_PERKS_COUNT)
      p.recommended <- true
    let perkCost = perksListVal?[p.perkId].cost ?? {}
    p.type <- perkCost.keys()?[0] ?? "other"
    foreach (idx, pPointId in pPointsList) {
      let cost = perkCost?[pPointId] ?? 0
      p.totalCost += cost
      p.isAvailable = p.isAvailable
        && (cost + (pointsInfo.used?[pPointId] ?? 0) <= (pointsInfo.total?[pPointId] ?? 0))
      if (pPointId in perkCost)
        p.costMask = p.costMask | (1 << idx)
    }
  })

  paramsList.sort(@(a, b) b.isAvailable <=> a.isAvailable
    || a.costMask <=> b.costMask
    || b.totalCost <=> a.totalCost)

  let typedPerks = array(pPointsList.len()).map(@(_) [])

  paramsList.each(function(perk){
    let perkType = perk.type
    let idxToAppend = pPointsList.indexof(perkType)
    if (idxToAppend != null)
      typedPerks[idxToAppend].append(perk)
  })

  return typedPerks
}

let function mkTierPossiblePerks(armyId, tier, pointsInfo) {
  let perks = clone tier.perks
  tier.slots.each(@(perkId) removeOnce(perks, perkId))
  if (!perks.len())
    return null
  let paramsList = uniteEqualPerks(tier.perks)

  return function() {
    let typedPerks = splitPerksByType(paramsList, perksList.value, tier.perks, pointsInfo)

    return {
      watch = perksList
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        tierTitle(tier)
        mkPerksList(armyId, typedPerks)
      ]
    }
  }
}

let function openAvailablePerks(perksListTable, armyId, sPerks) {
  let tiers = sPerks?.tiers ?? []
  if (!tiers.len())
    return

  let pointsInfo = getPerkPointsInfo(perksListTable, sPerks)
  let content = tiers.map(@(t) mkTierPossiblePerks(armyId, t, pointsInfo))
    .filter(@(c) c != null)
  open(content, loc("possible_perks_list/desc"))
}

return {
  openAvailablePerks
}
