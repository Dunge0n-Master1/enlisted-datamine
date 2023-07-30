from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let faComp = require("%ui/components/faComp.nut")
let { activeTxtColor, soldierLvlColor, titleTxtColor, accentColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallPadding, midPadding, bigPadding, startBtnWidth, attentionTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
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
let spinner = require("%ui/components/spinner.nut")
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
let { dynamicSeasonBPIcon } = require("battlePassPkg.nut")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let { dailyTasksUi } = require("%enlist/unlocks/taskWidgetUi.nut")
let weeklyTasksUi = require("%enlist/unlocks/weeklyTasksBtn.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")
let { canTakeDailyTaskReward } = require("%enlist/unlocks/taskListState.nut")


let waitingSpinner = spinner(hdpx(35))
let progressWidth = hdpxi(174)
let sizeBlocks    = fsh(40)
let sizeStar      = hdpx(15)
let hugePadding   = midPadding * 4
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
      gap = midPadding * 2
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
    rootBase = {
      key = "battlepassUnlocksRoot"
      behavior = Behaviors.Pannable
      wheelStep = 0.82
    }
  })
}

let progressStyles = {
  fa = { color = attentionTxtColor, font = fontawesome.font, fontSize = sizeStar }
}

let bpInfoStage = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    @() {
      rendObj = ROBJ_TEXT
      watch = progressCounters
      halign = ALIGN_CENTER
      text = loc("bp/currentStage", progressCounters.value)
      color = activeTxtColor
    }.__update(body_txt)
  ]
}

let starFilled = faComp("star", { fontSize = sizeStar, color = attentionTxtColor })
let starEmpty = faComp("star-o", { fontSize = sizeStar, color = attentionTxtColor })

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
    gap = midPadding
    margin = [0,0,0,midPadding]
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
  watch = [hasEliteBattlePass, canTakeDailyTaskReward]
  rendObj = ROBJ_TEXTAREA
  size = [pw(50), SIZE_TO_CONTENT]
  margin = [0, 0, 0, midPadding]
  text = !canTakeDailyTaskReward.value ? loc("unlocks/dailyTasksLimit")
    : hasEliteBattlePass.value ? loc("bp/progressWithPremium", fa)
    : loc("bp/howToProgress", fa)
  behavior = Behaviors.TextArea
  color = activeTxtColor
  tagsTable = progressStyles
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [-sizeBlocks, 0], to = [0, 0], duration = 0.2,
      easing = InOutCubic, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      easing = InOutCubic, play = true}
  ]
}.__update(sub_txt)

let bpInfoPremPass = function() {
  let res = { watch = hasEliteBattlePass }
  if (!hasEliteBattlePass.value)
    return res

  return res.__update({
    rendObj = ROBJ_TEXT
    text = loc("bp/battlePassBought")
    color = attentionTxtColor
  }, body_txt)
}

let btnReceiveReward = @() {
  watch = [hasReward, receiveRewardInProgress]
  halign = ALIGN_CENTER
  children = receiveRewardInProgress.value ? waitingSpinner
    : hasReward.value ? PrimaryFlat(loc("bp/getNextReward"), receiveNextReward, {
      hotkeys = [["^J:X | Enter | Space", { skip = true }]]
      size = btnSize
      margin = 0
    })
    : null
}

let premiumPassHeader = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/elite")
      color = attentionTxtColor
    }.__update(body_txt)
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePass")
      color = titleTxtColor
    }.__update(body_txt)
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
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [sizeBlocks, 0], to = [0, 0], duration = 0.2,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        easing = InOutCubic, play = true }
    ]
    margin = [midPadding, 0, bigPadding * 2, 0]
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      btnReceiveReward
      hasEliteBattlePass.value || !canBuyBattlePass.value ? null
        : btnBuyPremiumPass(loc("bp/buy"), eliteBattlePassWnd )
      buyUnlockInProgress.value ? waitingSpinner
        : price && !hasReward.value ? mkBtnBuySkipStage(price)
        : null
    ]
  })
}

let bpTasksBlock = @() {
  watch = serviceNotificationsList
  size = [startBtnWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  margin = [0,0,0,midPadding]
  children = serviceNotificationsList.value.len() > 0
    ? mkServiceNotification(serviceNotificationsList.value, { hplace = ALIGN_RIGHT })
    : [
        dailyTasksUi
        weeklyTasksUi
      ]
}

let bpRightBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = midPadding
  children = [
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        premiumPassHeader
        dynamicSeasonBPIcon(hdpxi(220))
        bpInfoPremPass
        bpInfoStage
      ]
    }
    buttonsBlock
  ]
}

let closeButton = closeBtnBase({ onClick = @() isOpened(false) })

let bpWindow = @(){
  size = flex()
  watch = [safeAreaBorders, hasEliteBattlePass, showingItem]
  padding = [
    safeAreaBorders.value[0] + hdpx(30),
    safeAreaBorders.value[1] + hdpx(25),
    safeAreaBorders.value[0] + hdpx(60),
    safeAreaBorders.value[1] + hdpx(25)
  ]
  flow = FLOW_VERTICAL
  children = [
    {
      flow = FLOW_VERTICAL
      behavior = Behaviors.MenuCameraControl
      size = flex()
      children = [
        bpHeader(showingItem.value, closeButton)
        {
          size = flex()
          children = [
            {
              flow = FLOW_VERTICAL
              gap = midPadding
              children = [
                {
                  margin = [midPadding,0,midPadding,0]
                  children = bpTitle(hasEliteBattlePass.value, hdpx(100))
                }
                bpInfoProgress
                bpTasksBlock
                bpInfoDetails
              ]
            }
            bpRightBlock
          ]
        }
      ]
    }
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