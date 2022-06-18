from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let { PrimaryFlat, Purchase } = require("%ui/components/textButton.nut")
let campaignTitle = require("%enlist/campaigns/campaign_title_small.ui.nut")
let { openUnlockSquadScene } = require("unlockSquadScene.nut")
let cratesPresentation = require("%enlSqGlob/ui/cratesPresentation.nut")
let { mkItemPromo, freemiumPromoLink } = require("components/itemRewardPromo.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let activatePremiumBttn = require("%enlist/shop/activatePremiumBtn.nut")
let buySquad = require("%enlist/shop/buySquadWindow.nut")
let { mkShopItemView, mkDiscountIcon } = require("%enlist/shop/shopPkg.nut")
let { mkPrice } = require("%enlist/shop/mkShopItemPrice.nut")
let { safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { get_army_level_reward } = require("%enlist/meta/clientApi.nut")
let { debounce } = require("%sqstd/timers.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { makeHorizScroll } = require("%darg/components/scrollbar.nut")
let armySelect = require("army_select.ui.nut")
let { mkBackWithImage, mkUnlockInfo, mkSquadBodyBottomSmall
} = require("mkSquadPromo.nut")
let { ModalBgTint, borderColor } = require("%ui/style/colors.nut")
let promoSmall = require("%enlist/currency/pkgPremiumWidgets.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { shadowStyle, bigGap, bigPadding, defBgColor, darkBgColor, freemiumColor, accentColor,
  freemiumDarkColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { curArmyData, armySquadsById, curUnlockedSquads } = require("model/state.nut")
let { curArmyLevels, curArmyExp, hasArmyUnlocks, allArmyUnlocks, uType,
  unlockSquad, curArmyLevel, curBuyLevelData,receivedUnlocks, curArmyNextUnlockLevel,
  levelWidth, showcaseItemWidth, hasCampaignSection, needUpdateCampaignScroll,
  isArmyUnlocksStateVisible, squadUnlockInProgress, squadGap,
  idxToForceScroll, scrollToCampaignLvl
} = require("model/armyUnlocksState.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { mkUnlockCampaignBlock } = require("lockCampaignPkg.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(58) })
let { progressBarHeight, completedProgressLine, acquiredProgresLine,
  progressContainerCtor, gradientProgressLine, imageProgressCtor
} = require("%enlist/components/mkProgressBar.nut")
let { weapInfoBtn, btnSizeSmall, progressBarWidth, rewardToScroll,
  receivedCommon, receivedFreemium
} = require("components/campaignPromoPkg.nut")
let { glareAnimation } = require("%enlSqGlob/ui/glareAnimation.nut")
let mkBuyArmyLevel = require("mkBuyArmyLevel.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { needFreemiumStatus, isFreemiumCampaign, isFreemiumBought
} = require("%enlist/campaigns/freemiumState.nut")

let tblScrollHandler = ScrollHandler()

let showSubLevels = Watched(false)
let squadMediumIconSize = [hdpx(85), hdpx(105)]

let summaryBlockHeight = hdpx(60)
let localGap = bigPadding * 2

let cardProgressBar = progressContainerCtor(
  $"!ui/uiskin/campaign/Campaign_progress_bar_mask.svg:{progressBarWidth}:{progressBarHeight}:K",
  $"!ui/uiskin/campaign/Campaign_progress_bar_border.svg:{progressBarWidth}:{progressBarHeight}:K",
  [progressBarWidth, progressBarHeight]
)

let emptyProgressBar = { size = [progressBarWidth, progressBarHeight] }

let primeCardProgressBar = imageProgressCtor($"!ui/gameImage/purchase_btn_bg.svg:{progressBarWidth}:{4}:K")

let unlockLocTxt = loc("squads/receive")

let mkUnlockCardButton = @(unlockInfo) function() {
  let { unlockText = null, unlockCb = null, isShowcase = false,
    lvlToBuy = null, cost = null, costFull = null, discount = null, isNextToBuyExp = false,
    isNextSquadUnlock = false, hasReceived = false, hasDiscount = false, isFreemium = false
  } = unlockInfo
  local children = []
  if (isNextToBuyExp) {
    if (!isFreemiumCampaign.value)
      children.append(mkBuyArmyLevel(lvlToBuy, cost, costFull))
    if (hasDiscount)
      children.append(mkDiscountIcon(discount, { pos = [0, -hdpx(30)] }))
  } else if (unlockCb == null && unlockText != null)
    children.append(mkUnlockInfo(unlockText))
  else if (!hasReceived
      && unlockCb != null
      && (!isFreemium || (isFreemiumCampaign.value && isFreemiumBought.value))) {
    let buttonCtor = isShowcase ? Purchase : PrimaryFlat
    children.append(buttonCtor(unlockText ?? unlockLocTxt,
      unlockCb,
      {
        margin = 0
        stopHover = true
        key = isNextSquadUnlock ? "squadReadyToUnlockButton" : null, //for tutorial
        size = btnSizeSmall
        hotkeys = unlockText == null ? [["^J:X", { action = unlockCb, description = unlockLocTxt }]] : []
      }))
  }
  if (!hasReceived && isFreemium && needFreemiumStatus.value)
    children.insert(0, freemiumPromoLink)

  return {
    watch = [isFreemiumCampaign, isFreemiumBought, needFreemiumStatus]
    vplace = ALIGN_BOTTOM
    minWidth = btnSizeSmall[0]
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT
    margin = [0, localGap, 0, 0]
    pos = [0, btnSizeSmall[1]/2]
    children
  }
}

let noImgBkg = { rendObj = ROBJ_SOLID, size = [pw(100), pw(75)], color = darkBgColor }

let mkSquadSmallCard = kwarg(function(squadCfg, armyId, unlockInfo, squad = null,
      summary = null, isPrimeSquad = false, onClick = null,
      progressWatch = Watched(null)) {
  let isLocked = squad == null
  let { image = null, icon = null } = squadCfg
  let { hasReceived = false, isFreemium = false } = unlockInfo
  let squadData = squadCfg.__merge({
    armyId, isLocked, isPrimeSquad, squadCfg, unlockInfo, hasReceived, isFreemium
  })

  let controlBlock = @(){
    watch = progressWatch
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = progressWatch.value && progressWatch.value == squadData.id
      ? spinner
      : [
          summary
          mkUnlockCardButton(unlockInfo)
        ]
  }

  return watchElemState(@(sf){
    behavior = Behaviors.Button
    onClick = onClick ?? function() {
      rewardToScroll(unlockInfo.unlockUid)
      openUnlockSquadScene(squadData, KWARG_NON_STRICT)
    }
    xmbNode = XmbNode()
    key = unlockInfo?.isNextSquadUnlock ? "squadReadyToUnlock" : null //for tutorial
    size = flex()
    stopHover = true
    children = [
      image != null ? mkBackWithImage(image, isLocked) : noImgBkg
      {
        size = flex()
        children = [
          {
            size = flex()
            valign = ALIGN_BOTTOM
            padding = [0, bigPadding, bigPadding, bigPadding]
            children = mkSquadBodyBottomSmall(squadData, KWARG_NON_STRICT)
          }
          controlBlock
        ]
      }
      mkSquadIcon(icon, {
        size = squadMediumIconSize
        margin = hdpx(5)
        picSaturate = isLocked ? 0.3 : 1
      })
      !hasReceived ? null
        : isFreemium ? receivedFreemium
        : receivedCommon
      weapInfoBtn(sf)
    ]
  })
})


let mkLevelFrame = @(children) {
  rendObj = ROBJ_SOLID
  size = [levelWidth - bigPadding, fsh(60)]
  color = defBgColor
  children = children
}

let mkEmptyLevelUnlock = {
  behavior = Behaviors.Button
  xmbNode = XmbNode()
  children = mkLevelFrame(txt({
    text = loc("willBeAvailableSoon")
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(body_txt)))
}

let mkSquadBlockByUnlock = @(unlock, armyData) function() {
  let { level, unlockId, isFreemium = false, exp = 0 } = unlock
  let armyId = armyData.guid
  let squadCfg = squadsCfgById.value?[armyId][unlockId]
  let squad = armySquadsById.value?[armyId][unlockId]
  let unlockInfo = {
    hasReceived = squad != null
    unlockUid = unlock.uid
  }
  if (squad == null) {
    let isActive = !isFreemium || !needFreemiumStatus.value
    let isNext = curArmyNextUnlockLevel.value == level
    let canUnlock = armyData.level >= level && armyData.exp >= exp
    unlockInfo.__update({
      unlockText = isFreemium && needFreemiumStatus.value ? loc("squads/freemiumNeeded")
        : !canUnlock ? loc("squads/unlockInfo", { level })
        : !isNext ? loc("squads/needUnlockPrev")
        : null
      unlockCb = isNext && canUnlock && isActive
        ? @() unlockSquad(unlockId)
        : null
      isNextSquadUnlock = isNext && canUnlock
      isNextToBuyExp = isNext && !canUnlock && !isFreemiumCampaign.value
      lvlToBuy = curArmyLevel.value
      cost = curBuyLevelData.value?.cost
      costFull = curBuyLevelData.value?.costFull
      hasDiscount = curBuyLevelData.value?.hasDiscount
      discount = curBuyLevelData.value?.discount
      isFreemium
    })
  }
  return {
    watch = [squadsCfgById, armySquadsById, curArmyNextUnlockLevel, curArmyLevel,
      curBuyLevelData, isFreemiumCampaign, needFreemiumStatus]
    children = squadCfg == null ? null
      : mkLevelFrame(
          mkSquadSmallCard({ squad, armyId, unlockInfo, squadCfg,
            progressWatch = squadUnlockInProgress })
        )
  }
}

let mkLevelRewardCard = @(unlock, armyData) function() {
  let { level, isFreemium = false, exp = 0 } = unlock
  local unlockInfo = {
    unlockUid = unlock.uid
    isFreemium
  }
  if (unlock.unlockGuid not in receivedUnlocks.value) {
    let isActive = !isFreemium || !needFreemiumStatus.value
    let isNext = curArmyNextUnlockLevel.value == level
    let canUnlock = armyData.level >= level && armyData.exp >= exp
    unlockInfo.__update({
      unlockText = isFreemium && needFreemiumStatus.value ? loc("squads/freemiumNeeded")
        : !canUnlock ? loc("squads/unlockInfo", { level })
        : !isNext ? loc("squads/needUnlockPrev")
        : ""
      unlockCb = isNext && canUnlock && isActive
        ? @() get_army_level_reward(armyData.guid, unlock.unlockGuid)
        : null
      isNextToBuyExp = isNext && !canUnlock && !isFreemiumCampaign.value
      lvlToBuy = curArmyLevel.value
      cost = curBuyLevelData.value?.cost
      costFull = curBuyLevelData.value?.costFull
    })
  }
  return {
    watch = [receivedUnlocks, curArmyNextUnlockLevel, curArmyLevel, curBuyLevelData,
      isFreemiumCampaign, needFreemiumStatus]
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    children = mkLevelFrame(
      mkItemPromo({
        armyId = unlock.armyId
        itemTpl = unlock.rewardInfo.rewardId
        presentation = cratesPresentation?[unlock.unlockId]
        unlockInfo
      })
    )
  }
}

let function mkShowcaseItem(shopItemGuid, uid) {
  let shopItem = shopItems.value?[shopItemGuid]
  if (shopItem == null)
    return null

  let shopSquad = shopItem?.squads[0]
  // now showcase can displays only shop items contains squads
  if (shopSquad == null)
    return null

  let { armyId = null, id = null } = shopSquad
  if (armyId == null || id == null)
    return null

  let { armyLevel = 0 } = shopItem?.requirements
  let isLocked = armyLevel > curArmyData.value.level
  if (isLocked)
    return null

  let productView = {
    rendObj = ROBJ_SOLID
    size = [showcaseItemWidth, showcaseItemWidth / 2]
    padding = hdpx(1)
    color = borderColor(0, false)
    clipChildren = true
    children = mkShopItemView({
      shopItem
    })
  }

  let openBuySquadScene = @() buySquad({
    shopItem, productView, armyId, squadId = id
  })

  let squadCfg = squadsCfgById.value?[armyId][id]
  let squad = armySquadsById.value?[armyId][id]
  let unlockInfo = {
    isShowcase = true
    unlockText = loc("squads/purchase")
    unlockCb = @() buyShopItem({
      shopItem
      activatePremiumBttn
      productView
      viewBtnCb = openBuySquadScene
    })
    unlockUid = uid
  }

  let isPrimeSquad = unlockInfo?.isShowcase != null && unlockInfo.isShowcase

  let summary = mkPrice({
    shopItem,
    bgParams = {
      size = [SIZE_TO_CONTENT, summaryBlockHeight]
      valign = ALIGN_TOP
      hplace = ALIGN_CENTER
    }
  })
  return {
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    onClick = openBuySquadScene
    children = mkLevelFrame(
      squadCfg == null ? null
        : mkSquadSmallCard({ squad, armyId, squadCfg, unlockInfo, summary, isPrimeSquad,
            onClick = function() {
              rewardToScroll(uid)
              openBuySquadScene()
            }
          })
    )
  }
}

let progressTxt = @(leftTxt = "", rightTxt = ""){
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_CENTER
  padding = [0, hdpx(50)]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = leftTxt
    }.__update(body_txt, shadowStyle)
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_RIGHT
      text = rightTxt
    }.__update(body_txt, shadowStyle)
  ]
}

let function freemiumProgressBar(nextUnlockLvl, level, expCur,
  expToReceive, progress, hasNotReceivedReward, hasFreemium
){
  if (nextUnlockLvl == level && expCur == expToReceive && hasNotReceivedReward && hasFreemium)
    return completedProgressLine(1, glareAnimation(2), freemiumColor, freemiumDarkColor)
  else if (nextUnlockLvl > level && expCur >= expToReceive)
    return acquiredProgresLine(1, [], freemiumColor, freemiumColor)

  progress = expToReceive > 0
    ? 1.0 - (expToReceive - expCur) / expToReceive.tofloat()
    : 0.0
  return gradientProgressLine(progress, "!ui/uiskin/progress_bar_freemium_gradient.svg")
}

let function progressBarVariation(nextUnlockLvl, level, expCur,
                                      expToReceive, progress, hasNotReceivedReward){
  if (nextUnlockLvl == level && expCur == expToReceive && hasNotReceivedReward)
    return completedProgressLine(1, glareAnimation(2))
  else if (nextUnlockLvl > level)
    return acquiredProgresLine(1, [], accentColor)

  progress = expToReceive > 0
    ? 1.0 - (expToReceive - expCur) / expToReceive.tofloat()
    : 0.0
  return gradientProgressLine(progress)
}


let levelsUnlocks = function() {
  let army = curArmyData.value
  local hasNotReceivedReward = false
  let children = allArmyUnlocks.value.map(function(unlock) {
    local unlockObj = mkEmptyLevelUnlock
    let { unlockType, level = 0, isFreemium = false } = unlock

    if (unlockType == uType.SQUAD) {
      unlockObj = mkSquadBlockByUnlock(unlock, army)
      hasNotReceivedReward = curUnlockedSquads.value.findvalue(@(value)
        value.squadId == unlock.unlockId) == null
    }
    else if (unlockType == uType.ITEM) {
      unlockObj = mkLevelRewardCard(unlock, army)
      hasNotReceivedReward = unlock.unlockGuid not in receivedUnlocks.value
    }
    else if (unlockType == uType.SHOP)
      unlockObj = mkShowcaseItem(unlock.guid, unlock.uid)

    local expToReceive = 0
    local expCur  = 0
    let progress = 0
    if (level > 0) {
        expToReceive = level <= curArmyLevels.value.len()
          ? curArmyLevels.value[level - 1].expTo - curArmyLevels.value[level - 1].expFrom
          : 0
        expCur = (level - 1) == curArmyLevel.value ? curArmyExp.value
          : level <= curArmyLevel.value ? expToReceive
          : 0
    }

    local progressBar = emptyProgressBar
    if (unlockType == uType.SHOP)
      progressBar = cardProgressBar(primeCardProgressBar, progressTxt(loc("squads/premiumSquad")))
    else if (unlockType != uType.EMPTY) {
      let progressObj = isFreemium
        ? freemiumProgressBar(curArmyNextUnlockLevel.value, level, expCur,
          expToReceive, progress, hasNotReceivedReward, isFreemiumBought.value)
        : progressBarVariation(curArmyNextUnlockLevel.value, level, expCur,
            expToReceive, progress, hasNotReceivedReward)
      let progressChild = progressTxt($"{loc("level")} {level}", $"{expCur}/{expToReceive}")
      progressBar = cardProgressBar(progressObj, progressChild)
    }

    return {
      margin = [0,0, bigPadding * 5,0]
      gap = squadGap
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        progressBar
        unlockObj
      ]
    }
  })

  return {
    watch = [
      curArmyData, curArmyExp, allArmyUnlocks, curArmyNextUnlockLevel, curUnlockedSquads,
      receivedUnlocks, curArmyLevels, curArmyLevel, isFreemiumBought
    ]
    flow = FLOW_HORIZONTAL
    gap = squadGap
    children = children
  }
}

let unlocksBlock = {
  margin = [0, 0, bigGap, 0]
  flow = FLOW_VERTICAL
  children = levelsUnlocks
}

let noArmyUnlocks = freeze({
  rendObj = ROBJ_SOLID
  size = flex()
  color = ModalBgTint
  children = {
    rendObj = ROBJ_TEXT
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    text = loc("willBeAvailableSoon")
  }.__update(body_txt)
})

let isBtnArrowLeftVisible = Watched(false)
let isBtnArrowRightVisible = Watched(true)

let function updateArrowButtons(elem) {
  isBtnArrowLeftVisible(elem.getScrollOffsX() > 0)
  isBtnArrowRightVisible(elem.getContentWidth() - elem.getScrollOffsX() > safeAreaSize.value[0])
}

tblScrollHandler.subscribe(function(_) {
  let elem = tblScrollHandler.elem
  if (elem == null)
    return

  updateArrowButtons(elem)
})


let function getPositionByLvl() {
  let curLvl = curArmyNextUnlockLevel.value
  if (curLvl <= 2)
    return 0

  local neededIdx = curLvl - 1

  if(idxToForceScroll.value != null){
    neededIdx = idxToForceScroll.value
    idxToForceScroll(null)
  }

  if(rewardToScroll.value != null){
    neededIdx = allArmyUnlocks.value.findindex(@(val) val.uid == rewardToScroll.value) ?? neededIdx
    rewardToScroll(null)
  }

  let lvlWidth = progressBarWidth + squadGap
  return ((neededIdx + 0.5) * lvlWidth).tointeger()
}

let function updateProgressScrollPos() {
  let xPos = getPositionByLvl()
  tblScrollHandler.scrollToX((xPos - safeAreaSize.value[0] / 2).tointeger())
}

let updateProgressScrollOnce = debounce(function(_) {
  updateProgressScrollPos()
  needUpdateCampaignScroll(false)
}, 0.1)

foreach (val in [curArmyData, needUpdateCampaignScroll])
  val.subscribe(updateProgressScrollOnce)

console_register_command(@() showSubLevels(!showSubLevels.value), "ui.campaignRewardsToggle")

let scrollArrowBtnStyle = {
  rendObj = ROBJ_SOLID
  size = [hdpx(60), flex()]
  margin = [0,0,hdpx(16),0]
  color = Color(0,0,0,200)
  iconParams = {
    fontSize = hdpx(36)
  }
}

let function scrollByArrow(dir) {
  let elem = tblScrollHandler?.elem
  if (elem == null)
    return

  tblScrollHandler.scrollToX((elem.getScrollOffsX()
    + (progressBarWidth + squadGap) * dir).tointeger())
  updateArrowButtons(elem)
}

let monetizationBlock = @(isVisible) !isVisible ? null
  : promoSmall("army_unlocks", null, {
      size = [flex(), SIZE_TO_CONTENT]
      color = defBgColor
      padding = bigGap
      margin = [hdpx(3),0,0,0]
    }, "premium/buyForExperience", body_txt)

let unlocksProgressBlock = @(isVisible) !isVisible ? noArmyUnlocks
  : @(){
      watch = [curArmyNextUnlockLevel, curArmyLevel, needFreemiumStatus]
      valign = ALIGN_CENTER
      size = flex()
      children = [
        makeHorizScroll({
          xmbNode = XmbContainer({
            canFocus = @() false
            scrollSpeed = 10.0
            isViewport = true
          })
          children = unlocksBlock
          onAttach = function(){
            if(idxToForceScroll.value == null){
              let lvlToScroll = needFreemiumStatus.value
                ? curArmyLevel.value + 1
                : curArmyNextUnlockLevel.value
              scrollToCampaignLvl(lvlToScroll)
            }
            updateProgressScrollPos()
          }
        }, {
          size = [flex(), SIZE_TO_CONTENT]
          scrollHandler = tblScrollHandler
          rootBase = class {
            behavior = Behaviors.Pannable
            wheelStep = 1
          }
        })
        @() {
          watch = isBtnArrowLeftVisible
          size = [SIZE_TO_CONTENT, flex()]
          children = isBtnArrowLeftVisible.value
            ? fontIconButton("angle-left", scrollArrowBtnStyle.__merge({
                onClick = @() scrollByArrow(-1)
              }))
            : null
        }
        @() {
          watch = isBtnArrowRightVisible
          size = [SIZE_TO_CONTENT, flex()]
          hplace = ALIGN_RIGHT
          children = isBtnArrowRightVisible.value
            ? fontIconButton("angle-right", scrollArrowBtnStyle.__merge({
                onClick = @() scrollByArrow(1)
              }))
            : null
        }
      ]
    }

let function topBlock(){
  let unlockList = lockedProgressCampaigns.value?[curCampaign.value]
  return {
    watch = [curCampaign, lockedProgressCampaigns, hasArmyUnlocks]
    size = [flex(), SIZE_TO_CONTENT]
    children = unlockList == null
      ? monetizationBlock(hasArmyUnlocks.value != null)
      : mkUnlockCampaignBlock(unlockList)
  }
}

let campaignBlock = @() {
  watch = hasArmyUnlocks
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        armySelect()
        topBlock
        campaignTitle
      ]
    }
    unlocksProgressBlock(hasArmyUnlocks.value != null)
  ]
}

return @() {
  watch = hasCampaignSection
  size = flex()
  onAttach = @() isArmyUnlocksStateVisible(true)
  onDetach = @() isArmyUnlocksStateVisible(false)
  halign = ALIGN_RIGHT
  children = hasCampaignSection.value
    ? campaignBlock
    : mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
}
