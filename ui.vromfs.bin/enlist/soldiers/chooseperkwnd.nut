from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { blurBgColor, bigGap, defTxtColor, activeTxtColor, bigPadding,
  isWide, perkBigIconSize, perkIconSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let spinner = require("%ui/components/spinner.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { mkPerksPointsBlock, tierTitle, perkCard, perkUi, priceIconCtor, thumbIconSize
} = require("components/perksPackage.nut")
let { kindIcon, levelBlock} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { currencyBtn } = require("%enlist/currency/currenciesComp.nut")
let { curCampSoldiers, curArmy } = require("model/state.nut")
let { perkChoiceWndParams, perksData, getPerkPointsInfo, showActionError,
  perkActionsInProgress, changePerkCost, changePerks
} = require("model/soldierPerks.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { mkSoldiersData } = require("model/collectSoldierData.nut")
let { mkPerkChoiceSlot } = require("%enlist/soldiers/model/mkPerkChoiceSlot.nut")
let { openAvailablePerks } = require("availablePerksWnd.nut")
let textButton = require("%ui/components/textButton.nut")
let { RECOMMENDED_PERKS_COUNT } = require("%enlist/meta/perks/perksStats.nut")
let { needFreemiumStatus, disablePerkReroll } = require("%enlist/campaigns/campaignConfig.nut")

const WND_UID = "choose_perk_wnd"

let perkCardStyle = {
  skipDirPadNav = true
  flow = FLOW_VERTICAL
  fillColor = null
  size = [hdpx(200), SIZE_TO_CONTENT]
}

let isRollAnimation = Watched(false)

let localGap = bigGap * 3
let totalBlackBgColor = Color(0,0,0)
let headerHeight = hdpx(36)

let sPerks = Computed(@() perksData.value?[perkChoiceWndParams.value?.soldierGuid])
let cardsGap = hdpx(40)
let perksContentWidth = perkBigIconSize[0] * 5 + cardsGap * 4

let function removeOnce(arr, val) {
  let idx = arr.indexof(val)
  if (idx != null)
    arr.remove(idx)
}

let recommendedPerkIds = Computed(function(){
  let { tiers = [] } = sPerks.value
  if (tiers.len() == 0)
    return []
  foreach (tier in tiers) {
    let perks = clone tier.perks
    tier.slots.each(@(perkId) removeOnce(perks, perkId))
    let perksSize = perks.len()
    if (perksSize > 0)
      return perks.resize(min(perksSize, RECOMMENDED_PERKS_COUNT))
  }
  return []
})

let soldier = mkSoldiersData(Computed(@()
  curCampSoldiers.value?[perkChoiceWndParams.value?.soldierGuid]))
let perkPointsInfoWatch = Computed(@() sPerks.value == null ? null
  : getPerkPointsInfo(sPerks.value, [sPerks.value?.prevPerk]))
let needShow = Computed(@() sPerks.value != null
  && (perkChoiceWndParams.value?.choice.len() ?? 0) > 0)

let close = function() {
  if (isRollAnimation.value) {
    isRollAnimation(false)
    anim_skip("perks_roll_anim")
    return
  }
  perkChoiceWndParams(null)
}

let closeButton = closeBtnBase({ onClick = close })

let mkText = @(text) {
  rendObj = ROBJ_TEXT, color = defTxtColor, text
}.__update(h2_txt)


let possiblePerksBtn = @(_soldier) @() {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  watch = [curArmy, sPerks, isRollAnimation]
  margin = [bigPadding, 0]
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = isRollAnimation.value
    ? null
    : textButton.SmallFlat(loc("possible_perks_list"),
      @(_event) openAvailablePerks(curArmy.value, sPerks.value),
      { margin = 0,  padding = [bigPadding, 2 * bigPadding] })
  }

let wndHeader = {
  size = [flex(), headerHeight]
  valign = ALIGN_BOTTOM
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = mkText(loc("choose_new_perk"))
    }
    possiblePerksBtn(soldier)
  ]
}

let recPerksHeader = {
  size = [perkBigIconSize[0], SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    {
      size = [perkIconSize, perkIconSize]
      valign = ALIGN_CENTER
      padding = [0, 0, 0, hdpx(12)]
      children =  {
        rendObj = ROBJ_IMAGE
        size = [thumbIconSize, thumbIconSize]
        image = Picture($"!ui/uiskin/thumb.svg:{thumbIconSize}:{thumbIconSize}:K")
      }
    }
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      color = defTxtColor
      text = loc("recommended_perks_list")
    }.__update(body_txt)
  ]
}

let mkRecommendedPerks = @(armyId, perks) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = perks == null ? null : perks.map(@(perk)
    perkUi(armyId, perk, {}, {
      iconCtor = priceIconCtor
      isRecommended = false
    }))
}


let function recPerksList(){
  let tiers = sPerks.value?.tiers
  let exclude = sPerks.value?.prevPerk
  let content = tiers?.map(function(tier) {
    let perksList = tier.perks
    let perks = perksList.filter(@(p)
      p != null && !tier.slots.contains(p) && exclude != p
        && recommendedPerkIds.value.contains(p)
    )
    if (perks.len() == 0)
      return null
    return {
      size = [flex(), SIZE_TO_CONTENT]
      children = mkRecommendedPerks(curArmy.value, perks)
    }
  }).filter(@(c) c != null)

  return {
    watch = [sPerks, curArmy, recommendedPerkIds]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = content
  }
}

let recommendedPerksList = @(){
  watch = isRollAnimation
  size = [perkBigIconSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = isRollAnimation.value ? null : [
    recPerksHeader
    recPerksList
  ]
}

let perksChoice = function() {
  let choice = perkChoiceWndParams.value?.choice ?? []

  return {
    watch = [perkChoiceWndParams, isRollAnimation]
    flow = FLOW_HORIZONTAL
    gap = cardsGap
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = choice.map(@(perkId, idx)
      mkPerkChoiceSlot({
        idx = idx
        total = choice.len()
        perkId = perkId
        prevPerk = sPerks.value?.prevPerk
        isRollAnimation = isRollAnimation
        hasRoll = perkChoiceWndParams.value.isNewChoice && isRollAnimation.value
        costValue = perkPointsInfoWatch.value
        isRecommended = recommendedPerkIds.value.contains(perkId)
      }))
  }
}

let function changePerksAction() {
  if (!needShow.value)
    return
  let { soldierGuid, tierIdx, slotIdx } = perkChoiceWndParams.value
  changePerks(soldierGuid, tierIdx, slotIdx,
    @(choiceData) "errorText" in choiceData ? showActionError(choiceData.errorText)
      : perkChoiceWndParams(choiceData))
}

let changePerksMsg = @() purchaseMsgBox({
  price = changePerkCost.value
  currencyId = "EnlistedGold"
  title = loc("msg/changePerks")
  purchase = changePerksAction
  dontShowMeTodayId = "change_perks"
})


let function changePerksButton() {
  let res = { watch = [changePerkCost, disablePerkReroll] }
  let cost = changePerkCost.value
  if (cost <= 0 || disablePerkReroll.value)
    return res
  return res.__update({
    hplace = ALIGN_RIGHT
    children = currencyBtn({
      btnText = loc("btn/changePerks")
      currencyId = "EnlistedGold"
      price = cost
      cb = changePerksMsg
      style = {
        hotkeys = [[ "^J:Y",{
          description = loc("btn/changePerks")
          sound="click"
        }]]
        margin = 0
        borderWidth = hdpx(1)
        borderColor = blurBgColor
        fillColor =  totalBlackBgColor
        size = [SIZE_TO_CONTENT, hdpx(45)]
      }
      txtColor = defTxtColor
      txtHoverColor = activeTxtColor
    })
  })
}

let mkAvaliablePerks = @(armyId, perks) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = perks.map(@(perkData, idx) perkCard({
    armyId
    perkData = perkData
    slotNumber = idx
    customStyle = perkCardStyle
  }))
}

let function currentPerks(){
  let tiers = sPerks.value?.tiers
  let exclude = [sPerks.value?.prevPerk]
  let content = tiers?.map(function(tier) {
    let slots = tier.slots.filter(@(p) p != null && exclude.indexof(p) == null)
    if (!slots.len())
      return null
    return {
      size = [hdpx(200), SIZE_TO_CONTENT]
      valign = ALIGN_TOP
      children = [
        tierTitle(tier)
        mkAvaliablePerks(curArmy.value, slots.map(@(p) {perkId = p}))
      ]
    }
  }).filter(@(c) c != null)

  return {
    padding = [localGap,0,0,0]
    valign = ALIGN_TOP
    watch = [sPerks, curArmy]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    children = content
  }
}

let function footer() {
  let {
    guid = "", perksCount = 0, level = 1, maxLevel = 1, tier = 1
  } = soldier.value
  local perksLevel = min(level, maxLevel)
  return{
    watch = [perkActionsInProgress, isRollAnimation]
    gap = localGap
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    children = isRollAnimation.value ? null
      : perkActionsInProgress.value.len() > 0 ? spinner
      : [
        @() {
          flow = FLOW_VERTICAL
          watch = needFreemiumStatus
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            changePerksButton
            levelBlock({
              curLevel = perksCount
              leftLevel = max(perksLevel - perksCount, 0)
              lockedLevel = max(maxLevel - perksLevel, 0)
              fontSize = hdpx(20)
              hasLeftLevelBlink = true
              guid = guid
              isFreemiumMode = needFreemiumStatus.value
              tier = tier
            }).__update({ margin = 0, size = [flex(), SIZE_TO_CONTENT] })
            {
              rendObj = ROBJ_TEXT
              text = loc("current_perks_list")
              color = defTxtColor
            }
            currentPerks
          ]
        }]
  }
}

let soldierInfo = {
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  padding = [bigPadding,0]
  gap = bigPadding * 2
  children = [
    @() {
      watch = soldier
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        kindIcon(soldier.value?.sKind, hdpx(30), soldier.value?.sClassRare)
        mkText(getObjectName(soldier.value))
      ]
    }
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = bigPadding
      children = [
        mkPerksPointsBlock(perkPointsInfoWatch)
        {
          rendObj = ROBJ_TEXT
          text = loc("perks/unallocatedPerks")
          color = defTxtColor
        }
      ]
    }
  ]
}

let function choosePerkWnd() {
  isRollAnimation(perkChoiceWndParams.value.isNewChoice)
  return {
    size = flex()
    padding = [navHeight, 0, 0, 0]
    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_VERTICAL
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          closeButton
          soldierInfo
        ]
      }
      {
        size = [fsh(95), flex()]
        hplace = ALIGN_CENTER
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        gap = localGap
        children = [
          wndHeader
          {
            size = [perksContentWidth, SIZE_TO_CONTENT]
            hplace = ALIGN_CENTER
            children = [
              perksChoice
              isWide ? recommendedPerksList : null
            ]
          }
          footer
        ]
      }
    ]
  }
}

let open = @() addModalWindow({
  key = WND_UID
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  children = choosePerkWnd()
  onClick = close
})

if (needShow.value)
  open()

needShow.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
