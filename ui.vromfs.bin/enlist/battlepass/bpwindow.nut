from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let faComp = require("%ui/components/faComp.nut")
let {
  bigPadding, smallPadding, activeTxtColor, soldierLvlColor, titleTxtColor,
  accentTitleTxtColor, accentColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { safeAreaSize, safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { PrimaryFlat } = require("%ui/components/textButton.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curSelectedItem } = require("%enlist/showState.nut")
let {
  basicProgress, combinedUnlocks, nextUnlock,
  progressCounters, currentProgress, hasReward, receiveNextReward, buyNextStage,
  nextUnlockPrice, buyUnlockInProgress, receiveRewardInProgress, seasonIndex
} = require("bpState.nut")
let { BP_INTERVAL_STARS } = require("%enlSqGlob/bpConst.nut")
let { premiumStage0Unlock } = require("%enlist/unlocks/taskRewardsState.nut")
let { hasEliteBattlePass, canBuyBattlePass } = require("eliteBattlePass.nut")
let { prepareRewards } = require("rewardsPkg.nut")
let { currencyBtn } = require("%enlist/currency/currenciesComp.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let {
  bpHeader, bpTitle, sizeCard, mkCard, btnSize, btnBuyPremiumPass, gapCards
} = require("bpPkg.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(70) })
let eliteBattlePassWnd = require("eliteBattlePassWnd.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let {
  progressBarHeight, completedProgressLine, acquiredProgressLine,
  progressContainerCtor, gradientProgressLine, inactiveProgressCtor
} = require("%enlist/components/mkProgressBar.nut")
let { glareAnimation } = require("%enlSqGlob/ui/glareAnimation.nut")
let itemMapping = require("%enlist/items/itemsMapping.nut")
let { commonArmy } = require("%enlist/meta/profile.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { isOpened, curItem, RewardState, unlockToShow, combinedRewards, curItemUpdate } = require("bpWindowState.nut")
let { scenesListGeneration, getTopScene } = require("%enlist/navState.nut")


let progressWidth = hdpxi(174)
let sizeBlocks    = fsh(40)
let sizeStar      = hdpx(15)
let bpLogoSize    = [hdpxi(90), hdpxi(90)]
let hugePadding   = bigPadding * 4
let cardProgressBar = progressContainerCtor(
  $"!ui/uiskin/battlepass/progress_bar_mask.svg:{progressWidth}:{progressBarHeight}:K",
  $"!ui/uiskin/battlepass/progress_bar_border.svg:{progressWidth}:{progressBarHeight}:K",
  [progressWidth, progressBarHeight]
)
let progressBarImage = @(isReceived, isPremium) !isReceived && isPremium ?
  "!ui/uiskin/progress_bar_gray.svg" : "!ui/uiskin/progress_bar_gradient.svg"

let tblScrollHandler = ScrollHandler()

let showingItem = Computed(function() {
  if (curItem.value == null)
    return null

  let reward = curItem.value.reward
  let season = seasonIndex.value
  let weapId = reward?.specialRewards[season][curArmy.value]
  if (weapId != null){
    let { gametemplate = reward.gametemplate } = allItemTemplates.value?[curArmy.value][weapId]
    return reward.__merge({
      isSpecial = true
      gametemplate
    })
  }

  if ((curItem.value?.stage0idx ?? -1 ) >= 0)
    return reward.__merge({isPremium = true})

  foreach (item in unlockToShow.value) {
    if (item.stage == curItem.value?.stageIdx)
      return reward.__merge({isPremium = item?.isPremium ?? false})
  }

  return reward
})

showingItem.subscribe(function(item) {
  if (isOpened.value)
    curSelectedItem(item)
})

let progressTxt = @(text = "") {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  padding = [0, hdpx(20), 0, 0]
  rendObj = ROBJ_TEXT
  text
}.__update(body_txt)

let function scrollToCurrent() {
  let cardIdx = (curItem.value?.stageIdx ?? "0").tointeger()
    + (premiumStage0Unlock.value?.stages[0].rewards.len() ?? 0)
  tblScrollHandler.scrollToX((sizeCard[0] + gapCards) * (cardIdx + 0.5) - gapCards
    - safeAreaSize.value[0] / 2)
}

nextUnlock.subscribe( function(_) {
  curItemUpdate()
  scrollToCurrent()
})

let cardsList = function() {
  let { isFinished = false } = premiumStage0Unlock.value
  let { rewards  = {} } = premiumStage0Unlock.value?.stages[0]

  let mappedItems = itemMapping.value
  let templates = allItemTemplates.value?[commonArmy.value] ?? {}

  let children = [
    {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      gap = bigPadding * 2
      valign = ALIGN_BOTTOM
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = gapCards
          children = prepareRewards(rewards, mappedItems)
            .map(@(r, idx) mkCard(r.reward, r.count, templates,
              @() curItem({ reward = r.reward, stage0idx = idx }),
              Computed(@() curItem.value?.stage0idx == idx),
              isFinished, true,
              null))
        }
        {
          size = [flex(), progressBarHeight]
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = {
            rendObj = ROBJ_TEXT
            color = activeTxtColor
            text = loc("bp/eliteBPRewards")
          }
        }
      ]
    }
  ].extend(combinedRewards.value.map(@(r)
    mkCard(r.reward, r.count, templates,
      @() curItem({ reward = r.reward, stageIdx = r.stageIdx }),
      Computed(@() curItem.value?.stageIdx == r.stageIdx),
      r.isReceived,
      r.isPremium,
      cardProgressBar(
        r.progressState == RewardState.COMPLETED ? completedProgressLine(1, glareAnimation(0.5))
          : r.progressState == RewardState.ACQUIRED ? acquiredProgressLine(1, [], accentColor)
          : r.progressState == RewardState.IN_PROGRESS ?
            gradientProgressLine(r.progressVal, progressBarImage(r.isReceived, r.isPremium))
            : inactiveProgressCtor(),
        progressTxt(r.stageIdx + 1))
    )
  ))

  return {
    watch = [
      combinedRewards, premiumStage0Unlock, itemMapping, allItemTemplates, commonArmy
    ]
    flow = FLOW_HORIZONTAL
    gap = gapCards
    children
  }
}

let bpUnlocksList = @() {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  watch = safeAreaSize
  xmbNode = XmbContainer({
    canFocus = @() false
    scrollSpeed = 5.0
    isViewport = true
  })

  children = makeHorizScroll({
    flow = FLOW_VERTICAL
    padding = [hugePadding, 0, hugePadding, 0]
    gap = gapCards
    children = cardsList
    onAttach = scrollToCurrent
  }, {
    size = SIZE_TO_CONTENT
    maxWidth = safeAreaSize.value[0]
    scrollHandler = tblScrollHandler
    rootBase = class {
      key = "battlepassUnlocksRoot"
      behavior = Behaviors.Pannable
      wheelStep = 0.82
    }
  })
}

let progressStyles = {
  fa = { color = accentTitleTxtColor, font = fontawesome.font, fontSize = sizeStar }
}

let bpInfoStage = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    @() {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      watch = progressCounters
      text = loc("bp/currentStage", progressCounters.value)
      color = activeTxtColor
    }.__update(body_txt)
  ]
}

let starFilled = faComp("star", { fontSize = sizeStar, color = accentTitleTxtColor })
let starEmpty = faComp("star-o", { fontSize = sizeStar, color = accentTitleTxtColor })

let function bpInfoProgress () {
  let { current, required, interval } = currentProgress.value
  let starFactor = (interval / BP_INTERVAL_STARS).tointeger()
  let filledStars = current >= required || hasReward.value || starFactor == 0
    ? BP_INTERVAL_STARS
    : min(BP_INTERVAL_STARS - 1, ((current + interval - required) / starFactor).tointeger())

  return {
    valign = ALIGN_CENTER
    watch = [currentProgress, hasReward, basicProgress, combinedUnlocks, progressCounters]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("nextReward")
        color = hasReward.value ? soldierLvlColor: activeTxtColor
      }.__update(body_txt)
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = array(filledStars).map(@(_) starFilled)
          .extend(array(BP_INTERVAL_STARS - filledStars).map(@(_) starEmpty))
      }
    ]
  }
}

let bpInfoDetails = @() {
  watch = hasEliteBattlePass
  rendObj = ROBJ_TEXTAREA
  size = [pw(70), SIZE_TO_CONTENT]
  text = loc(hasEliteBattlePass.value ? "bp/progressWithPremium" : "bp/howToProgress", fa)
  behavior = Behaviors.TextArea
  color = activeTxtColor
  tagsTable = progressStyles
}.__update(sub_txt)

let bpInfoPremPass = function() {
  let res = { watch = hasEliteBattlePass }
  if (!hasEliteBattlePass.value)
    return res

  return res.__update({
    rendObj = ROBJ_TEXT
    text = loc("bp/battlePassBought")
    color = accentTitleTxtColor
  }, body_txt)
}

let btnReceiveReward = @() {
  watch = [hasReward, receiveRewardInProgress]
  hplace = ALIGN_CENTER
  children = receiveRewardInProgress.value ? spinner
    : hasReward.value ? PrimaryFlat(loc("bp/getNextReward"), receiveNextReward, {
      hotkeys = [["^J:X | Enter | Space", { skip = true }]]
      size = btnSize
      margin = 0
    })
    : null
}

let premiumPassHeader = {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/elite")
      color = accentTitleTxtColor
    }.__update(body_txt)
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePass")
      color = titleTxtColor
    }.__update(body_txt)
  ]
}

let buyPremiumPassHeader = @() {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = bigPadding * 2
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = bpLogoSize
      image = Picture($"!ui/uiskin/battlepass/bp_logo.svg:{bpLogoSize[0]}:{bpLogoSize[1]}:K")
    }
    premiumPassHeader
  ]
}

let mkBtnBuySkipStage = @(price) currencyBtn({
  btnText = loc("bp/buyNextStage")
  currencyId = price.currency
  price = price.price
  cb = @() purchaseMsgBox({
    price = price.price
    currencyId = price.currency
    description = loc("bp/buyNextStageConfirm")
    purchase = buyNextStage
    alwaysShowCancel = true
    srcComponent = "buy_battlepass_level"
  })
  style = ({
    margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
    size = [SIZE_TO_CONTENT, btnSize[1]]
    minWidth = btnSize[0]
  })
})

let function buttonsBlock() {
  let res = { watch = [ hasEliteBattlePass, canBuyBattlePass, nextUnlockPrice,
    buyUnlockInProgress, hasReward] }

  let price = nextUnlockPrice.value
  return res.__update({
    valign = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    size = [flex(), SIZE_TO_CONTENT]
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [sizeBlocks, 0], to = [0, 0], duration = 0.2,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        easing = InOutCubic, play = true }
    ]
    margin = [0,0, hugePadding, 0]
    children = [
      btnReceiveReward
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        children = [
          hasEliteBattlePass.value || !canBuyBattlePass.value ? null : {
            flow = FLOW_VERTICAL
            gap = hugePadding
            size = [btnSize[0], SIZE_TO_CONTENT]
            children = [
              buyPremiumPassHeader
              btnBuyPremiumPass(loc("bp/buy"), eliteBattlePassWnd )
            ]
          }
          buyUnlockInProgress.value ? spinner
            : price && !hasReward.value ? mkBtnBuySkipStage(price)
            : null
        ]
      }
    ]
  })
}


let bpLeftBlock = {
  size = [sizeBlocks, flex()]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = bigPadding * 2
  children = [
    bpInfoStage
    bpInfoProgress
    bpInfoDetails
    bpInfoPremPass
  ]
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [-sizeBlocks, 0], to = [0, 0], duration = 0.2,
      easing = InOutCubic, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      easing = InOutCubic, play = true}
  ]
}

let closeButton = closeBtnBase({ onClick = @() isOpened(false) })

let bpWindow = @(){
  size = flex()
  watch = [safeAreaBorders, hasEliteBattlePass, showingItem]
  padding = [safeAreaBorders.value[0] + hdpx(30), safeAreaBorders.value[1] + hdpx(25)]
  flow = FLOW_VERTICAL
  behavior = Behaviors.MenuCameraControl
  children = [
    bpHeader(showingItem.value, closeButton)
    {
      margin = [0,0,hdpx(80),0]
      children = bpTitle(hasEliteBattlePass.value, hdpx(100))
    }
    bpLeftBlock
    buttonsBlock
    bpUnlocksList
  ]
}

scenesListGeneration.subscribe(function(_v){
  if( getTopScene() == bpWindow )
    curItemUpdate()
})

let function open() {
  sceneWithCameraAdd(bpWindow, "battle_pass")
  curItemUpdate()
}

let function close() {
  sceneWithCameraRemove(bpWindow)
  curSelectedItem(null)
  curItem(null)
}

if (isOpened.value)
  open()

isOpened.subscribe(@ (v) v ? open() : close())