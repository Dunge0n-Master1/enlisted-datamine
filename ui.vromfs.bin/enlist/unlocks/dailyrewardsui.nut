from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let faComp = require("%ui/components/faComp.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(60) })
let { debounce } = require("%sqstd/timers.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { mkHeaderFlag, casualFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let itemMapping = require("%enlist/items/itemsMapping.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let { rand } = require("math")
let { withTooltip } = require("%ui/style/cursors.nut")
let { getCratesListComp } = require("%enlist/soldiers/model/cratesContent.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { Bordered, PrimaryFlat } = require("%ui/components/textButton.nut")
let { titleTxtColor, smallPadding, commonBtnHeight, bigPadding, smallOffset,
  defBgColor, defTxtColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { h0_txt, h1_txt, h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { noteTextArea, txt } = require("%enlSqGlob/ui/defcomps.nut")
let { dailyRewardsUnlock, receiveDayReward, dailyRewardsCrates, calcRewardCfg,
  isReceiveDayRewardInProgress, receivedDailyReward, getStageRewardsData,
  gotoNextStageOrClose, curBoosteredDailyTask, imitateCrateReward,
  getCurLoginUnlockStage
} = require("dailyRewardsState.nut")
let { makeCrateToolTip } = require("%enlist/items/crateInfo.nut")
let { progressBarHeight, completedProgressLine, acquiredProgressLine, progressContainerCtor
} = require("%enlist/components/mkProgressBar.nut")
let { mkRewardCardByPresentanion, mkAppearAnim, mkRollAnim, sizeCard,
  mkRewardCardByTemplate, animTrigger, mkMoveDownAnim, mkBoosterItemsView, wndParams
} = require("dailyRewardsPkg.nut")
let { clampStage } = require("%enlSqGlob/unlocks_utils.nut")
let { glareAnimation } = require("%enlSqGlob/ui/glareAnimation.nut")
let { mkRewardImages, rewardWidthToHeight } = require("%enlist/battlepass/rewardsPkg.nut")
let { commonArmy } = require("%enlist/meta/profile.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { mkUnlockSlot } = require("mkUnlockSlot.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let { isBooster } = require("%enlist/soldiers/model/boosters.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")


const WND_UID = "dailyRewardsWindow"
const REWARDS_IN_LINE = 7
const ROLL_CARD_COUNT = 10
const SHOW_WND_DELAY = 0.2
const SHOW_STAGE_DELAY = 0.1
const SHOW_REWARD_DELAY = 0.4
const ROLL_REWARD_DELAY = 0.6
const SHOW_TASK_BOOST = "show_task_boost"
const HIDE_TASK_BOOST = "hide_task_boost"


let hasRewardsAnim = Watched(false)

let rewardWidth = hdpxi(160)
let wndPadding = sh(1).tointeger()
let wndWidth = REWARDS_IN_LINE * rewardWidth + wndPadding * 2
let isOpened = mkWatched(persist, "isOpened", false)
let imageHeight = rewardWidth - hdpx(30)
let imageSize = [(rewardWidthToHeight * imageHeight).tointeger(), imageHeight]
let btnSize = [hdpx(280), commonBtnHeight]

let dayProgressBar = progressContainerCtor(
  $"!ui/uiskin/battlepass/progress_bar_mask.svg:{rewardWidth}:{progressBarHeight}:K",
  $"!ui/uiskin/battlepass/progress_bar_border.svg:{rewardWidth}:{progressBarHeight}:K",
  [rewardWidth, progressBarHeight]
)

let mkImage = @(path, override = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(override)

let mkProgressText = @(progressText) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = progressText
}.__update(body_txt)

let function mkStageCardView(rewardItems) {
  if (rewardItems.len() == 0)
    return null

  let moreNumber = rewardItems.len() - 1
  return {
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkRewardImages(rewardItems[0], imageSize, {
        pos = [0, -smallPadding]
      })
      moreNumber <= 0 ? null
        : txt({
            text = loc("plusMore", { number = moreNumber })
            padding = smallPadding
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            color = titleTxtColor
          })
    ]
  }
}

let function mkToolTip(rewardCrate, rewardsCfgs) {
  let headerText = "\n".join(rewardsCfgs.map(@(cfg) loc(cfg.name)))
  return rewardCrate.value != null
    ? makeCrateToolTip(rewardCrate, headerText)
    : tooltipBox(noteTextArea({
        size = [hdpx(400), SIZE_TO_CONTENT]
        text = headerText
        color = defTxtColor
      }).__update(sub_txt))
}

let function mkBoosterToolTip(bName, rewardsBoosters, rewardsItems, curArmyId) {
  let boostersItems = {
    reinforcing = []
    instant = []
  }
  foreach (boosterId, booster in rewardsBoosters)
    foreach (boosterPackIdx, boosterPack in booster) {
      let boostersPack = (boosterPack?.instantReward ?? false)
        ? boostersItems.instant
        : boostersItems.reinforcing
      foreach (mappedItem, count in boosterPack.items)
        boostersPack.append({
          boosterId, boosterPackIdx, mappedItem, count,
          itemTemplate = rewardsItems?[mappedItem].itemTemplate
          worth = rewardsItems?[mappedItem].worth ?? 0
        })
    }

  return tooltipBox({
    size = [hdpx(400), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      noteTextArea({
        size = [flex(), SIZE_TO_CONTENT]
        text = loc(bName)
        color = activeTxtColor
      }).__update(body_txt)
      mkBoosterItemsView(boostersItems, curArmyId, allItemTemplates, commonArmy)
    ]
  })
}

let function mkProgressBar(idx, todayStage, pastDays, hasStageReward, hasStageCompleted) {
  let progressObj = hasStageReward ? completedProgressLine(1, glareAnimation(3))
    : hasStageCompleted ? acquiredProgressLine(1)
    : null
  let progressText = idx == todayStage - 1 ? loc("today")
    : idx == todayStage ? loc("tomorrow")
    : loc("dayWithNumber", { number = pastDays + idx + 1 })
  return dayProgressBar(progressObj, mkProgressText(progressText))
}

let rewardBlinkAnim = [{
  prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], play = true,
  duration = 1.5, loop = true, easing = CosineFull
}]

let emptyStageCard = {
  size = [rewardWidth, rewardWidth]
  padding = wndPadding / 2
  children = {
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = flex()
  }
}

let mkStageCard = @(rewardsData, hasReward) {
  size = [rewardWidth, rewardWidth]
  padding = wndPadding / 2
  skipDirPadNav = false
  children = {
    rendObj = ROBJ_BOX
    size = flex()
    borderWidth = hdpx(1)
    clipChildren = true
    borderColor = hasReward
      ? wndParams.rewardColor
      : wndParams.baseColor
    children = [
      hasReward
        ? mkImage("ui/gameImage/enlisted_box_glow_small.png", {
            keepAspect = true
            transform = {}
            animations = rewardBlinkAnim
          })
        : null
      mkStageCardView(rewardsData)
    ]
  }
}

let mkDailyReward = @(idx, progressBar, stageCard) {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  gap = wndPadding
  children = [
    progressBar
    stageCard
  ]
  transform = {}
  animations = mkMoveDownAnim(SHOW_WND_DELAY + idx * SHOW_STAGE_DELAY)
}

let mkDailyRewardsContent = @(cratesCompWatch)
  function() {
    let res = {watch = [dailyRewardsUnlock, curArmy, cratesCompWatch, itemMapping]}
    if (dailyRewardsUnlock.value == null)
      return res
    let {
      stage = 0, lastRewardedStage = 0, hasReward = false, stages = [],
      required = 0, current = 0
    } = dailyRewardsUnlock.value

    let totalStages = stages.len()
    let passCycles = totalStages > 0 ? lastRewardedStage / totalStages : 0
    let pastDays = passCycles * totalStages
    let rewardStage = clampStage(dailyRewardsUnlock.value, lastRewardedStage)
    let activeStage = clampStage(dailyRewardsUnlock.value, stage)
    let todayStage = clampStage(dailyRewardsUnlock.value, stage + current - required + 1)
    let rewardsItems = itemMapping.value
    let cratesComp = cratesCompWatch.value
    let curArmyId = curArmy.value
    local startStage = totalStages <= REWARDS_IN_LINE ? 0
      : hasReward ? rewardStage - 1
      : activeStage - 2
    startStage = clamp(startStage, 0, totalStages - REWARDS_IN_LINE)
    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = [sh(4), wndPadding, 0, wndPadding]
      clipChildren = true
      children = stages.slice(startStage, startStage + REWARDS_IN_LINE)
        .map(function(stageData, idx) {
          let hasStageReward = idx + startStage == rewardStage && hasReward
          let hasStageCompleted = hasReward
            ? idx + startStage < rewardStage
            : idx + startStage < activeStage
          let progBar = mkProgressBar(idx + startStage, todayStage, pastDays,
            hasStageReward, hasStageCompleted)

          local stageCard = emptyStageCard
          if (stageData?.rewards) {
            let rewardsCfg = calcRewardCfg(stageData, rewardsItems, cratesComp, curArmyId)
            let { rewardCrate, rewardsData } = rewardsCfg
            stageCard = withTooltip(mkStageCard(rewardsData, hasStageReward),
              @() mkToolTip(rewardCrate, rewardsData))
          }
          else if (stageData?.rewardsBoosters) {
            let uBoosterId = stageData.rewardsBoosters.keys()?[0]
            let uBoostersPres = rewardsItems?[uBoosterId]
            let bName = uBoostersPres?.name
            stageCard = withTooltip(mkStageCard([uBoostersPres], hasStageReward),
              @() mkBoosterToolTip(bName, stageData.rewardsBoosters, rewardsItems, curArmyId))
          }

          return mkDailyReward(idx, progBar, stageCard)
        })
    })
  }

let dailyRewardsHeader = {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    mkHeaderFlag({
      rendObj = ROBJ_TEXT
      text = loc("dailyRewards/header")
      padding = [sh(1.5), sh(9), sh(1.5), sh(3)]
    }.__update(h0_txt),
    casualFlagStyle)
    noteTextArea({
      text = loc("dailyRewards/desc")
      size = [pw(40), SIZE_TO_CONTENT]
      margin = [0,sh(2),0,0]
      color = titleTxtColor
      hplace = ALIGN_RIGHT
    }).__update(h2_txt)
  ]
}

let btnParams = {
  size = btnSize
  hotkeys = [[$"^{JB.A} | Enter | Space | Esc", { description = { skip = true }} ]]
  margin = 0
}

let function skipRewardAnimCb() {
  anim_skip(animTrigger)
  anim_skip(HIDE_TASK_BOOST)
  anim_start(SHOW_TASK_BOOST)
  hasRewardsAnim(false)
}

let function nextOrCloseCb(receivedData) {
  gotoNextStageOrClose(receivedData, @() isOpened(false))
}

let mkButton = @(receivedData) function() {
  let rData = receivedData.value
  local button = Bordered(loc("Close"), @() nextOrCloseCb(rData), btnParams)
  if (isReceiveDayRewardInProgress.value)
    button = spinner
  else if (rData != null) {
    if (hasRewardsAnim.value)
      button = Bordered(loc("Skip"), skipRewardAnimCb, btnParams)
    else
      button = Bordered(loc("Ok"), @() nextOrCloseCb(rData), btnParams)
  }
  else if (dailyRewardsUnlock.value?.hasReward)
    button = PrimaryFlat(loc("bp/getNextReward"), receiveDayReward, btnParams)

  return {
    watch = [isReceiveDayRewardInProgress, receivedData, dailyRewardsUnlock, hasRewardsAnim]
    size = [flex(), sh(7)]
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    children = {
      pos = [-hdpx(30), hdpx(30)]
      children = button
    }
  }
}

let mkRewardItemCard = kwarg(@(itemTemplate = null, count = 1, presentanion = null)
  presentanion != null
    ? mkRewardCardByPresentanion(presentanion, count, allItemTemplates, commonArmy)
    : mkRewardCardByTemplate(itemTemplate, allItemTemplates, commonArmy)
)

let function mkRollReward(cratesContent, rewardCard, animDelay, onEnter, onFinish) {
  let children = [rewardCard]
  let itemsTpls = cratesContent.keys()
  let total = itemsTpls.len()
  for (local i = 0; i < ROLL_CARD_COUNT; i++) {
    let randIdx = rand() % total
    children.append(mkRewardItemCard(cratesContent[itemsTpls[randIdx]]))
  }
  return {
    flow = FLOW_VERTICAL
    children
    transform = {}
    animations = mkRollAnim(animDelay, -sizeCard[1] * (ROLL_CARD_COUNT + 1),
      onEnter, onFinish, "ui/debriefing/squad_star")
  }
}

let rewardBg = {
  size = flex()
  clipChildren = true
  children = mkImage("ui/gameImage/enlisted_box_glow_small.png", {
    size = [pw(160), ph(160)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  })
}

let function mkCrateReward(itemTpl, count, animDelay, cratesContent, onEnter, onFinish) {
  let itemData = cratesContent?[itemTpl]
  if (itemData == null)
    return null

  let rewardCard = mkRewardItemCard(itemData.__merge({ count }))
  let itemTooltip = tooltipBox(function() {
    let { itemTemplate = "", presentanion = {} } = itemData
    let { name = "" } = presentanion
    let template = allItemTemplates.value?[commonArmy.value][itemTemplate]
    return {
      watch = [hasRewardsAnim, allItemTemplates, commonArmy]
      children = txt(hasRewardsAnim.value ? loc("definingReward")
        : isBooster(template) ? getItemName(template)
        : name != "" ? loc(name)
        : null)
    }
  })
  return {
    rendObj = ROBJ_BOX
    padding = hdpx(1)
    borderColor = wndParams.rewardColor
    children = {
      size = sizeCard
      clipChildren = true
      children = [
        rewardBg
        mkRollReward(cratesContent, rewardCard, animDelay, onEnter, onFinish)
        withTooltip({
          size = flex()
          skipDirPadNav = false
        }, @() itemTooltip)
      ]
    }
  }
}

let mkItemReward = @(itemData, idx, total) {
  children = [
    rewardBg
    mkRewardItemCard(itemData)
  ]
}.__update({
    onAttach = @() hasRewardsAnim(true)
    transform = {}
    animations = mkAppearAnim(idx * SHOW_REWARD_DELAY + 0.5,
      idx >= total - 1
        ? @() hasRewardsAnim(false)
        : null,
      "ui/debriefing/squad_star")
  })

let function mkRewards(receivedRewards) {
  let { itemsData, cratesContent, crateItemsData = {} } = receivedRewards
  let itemsList = itemsData.values()
  let itemsTotal = itemsList.len()
  let cratesItemsTotal = crateItemsData.len()

  local animDelay = itemsTotal * SHOW_REWARD_DELAY
  local idx = 1

  let res = itemsList.map(@(itemData, idx)
    mkItemReward(itemData, idx, itemsTotal))
  foreach (itemTpl, itemData in crateItemsData) {
    let onEnter = idx == 1 ? @() hasRewardsAnim(true) : null
    let onFinish = idx >= cratesItemsTotal
      ? function() {
          hasRewardsAnim(false)
          anim_skip(HIDE_TASK_BOOST)
          anim_start(SHOW_TASK_BOOST)
        }
      : null
    res.append(mkCrateReward(itemTpl, itemData?.count ?? 1,
      animDelay, cratesContent, onEnter, onFinish))
    animDelay += ROLL_REWARD_DELAY
    idx++
  }
  return res
}

let mkFaComp = @(text) faComp(text, {
  fontSize = hdpx(30)
  color = titleTxtColor
})

let mkAppearAnimations = @() [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = 10, play = true,
    trigger = HIDE_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
    trigger = SHOW_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.8,
    trigger = SHOW_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.translate, from = [hdpx(70), -hdpx(100)], to = [0,0],
    duration = 0.8, trigger = SHOW_TASK_BOOST, easing = OutQuart }
]

let mkBoosterRewards = @(receivedRewards) {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = smallOffset
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = mkRewards(receivedRewards)
    }
    mkFaComp("arrow-circle-right")
    {
      rendObj = ROBJ_SOLID
      flow = FLOW_VERTICAL
      padding = bigPadding
      color = defBgColor
      children = [
        txt({
          text = loc("unlockBoosterTitle")
          padding = bigPadding
          hplace = ALIGN_CENTER
          color = titleTxtColor
        }).__update(sub_txt)
        {
          rendObj = ROBJ_SOLID
          size = [startBtnWidth, SIZE_TO_CONTENT]
          padding = [bigPadding, 0]
          color = defBgColor
          children = mkUnlockSlot({
            task = receivedRewards.boosteredTask
            rewardsAnim = mkAppearAnimations()
          })
        }
      ]
    }
  ]
}

let mkDailyRewardsAnimation = @(receivedData)
  function() {
    let receivedDataVal = receivedData.value
    return {
      watch = receivedData
      size = [flex(), sh(25)]
      flow = FLOW_HORIZONTAL
      gap = wndPadding
      padding = wndPadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = receivedDataVal == null ? null
        : "hasRewards" in receivedDataVal ? mkRewards(receivedDataVal)
        : "hasBoosters" in receivedDataVal ? mkBoosterRewards(receivedDataVal)
        : null
    }
  }

let mkDailyRewardsHeader = @(receivedData)
  @() {
    watch = receivedData
    size = [flex(), sh(6)]
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = receivedData.value == null ? null
      : {
          rendObj = ROBJ_TEXT
          text = loc("youHaveReceived")
          transform = {}
          animations = mkAppearAnim(0, null, "ui/debriefing/squad_progression_appear")
        }.__update(h1_txt)
  }

let function dailyRewards() {
  let cratesCompWatch = getCratesListComp(dailyRewardsCrates)
  let receivedData = keepref(Computed(function() {
    let unlock = dailyRewardsUnlock.value
    let mappedItems = itemMapping.value
    let cratesComp = cratesCompWatch.value
    let boosteredTask = curBoosteredDailyTask.value
    let stageData = getCurLoginUnlockStage(unlock)

    let { rewardsBoosters = {}, rewards = {} } = stageData

    // if reward is reinforcing booster fo unlock
    if (boosteredTask != null) {
      let receivedBoosters = []
      foreach (mapedItem, count in boosteredTask?.boosterLog.reward.items ?? {}) {
        let basetpl = mappedItems?[mapedItem].itemTemplate
        if (basetpl != null)
          receivedBoosters.append({ basetpl, count })
      }
      return receivedBoosters.len() == 0 ? null
        : imitateCrateReward(rewardsBoosters, receivedBoosters, mappedItems)
            .__update({ boosteredTask })
    }

    let receivedRewardData = receivedDailyReward.value
    if (receivedRewardData == null)
      return null

    let { curArmyId, receivedItems } = receivedRewardData

    // if reward is instant booster (similar crate open)
    if (rewardsBoosters.len() > 0)
      return imitateCrateReward(rewardsBoosters, receivedItems, mappedItems, "hasRewards")

    let res = getStageRewardsData(rewards, mappedItems, cratesComp, curArmyId)

    let crateItemsData = {}
    foreach (receivedItem in receivedItems) {
      let { basetpl, count } = receivedItem
      let itemData = res.itemsData?[basetpl]

      if (basetpl in res.cratesContent) {
        let crateCount = count - (itemData?.count ?? 0)
        if (crateCount > 0)
          crateItemsData[basetpl] <- {
            count = crateCount
            itemTemplate = basetpl
          }
      }
      if (itemData != null)
        itemData.count <- min(itemData.countCfg, count)
    }
    res.itemsData = res.itemsData.filter(@(v) (v?.count ?? 0) > 0)
    if (crateItemsData.len() == 0 && res.itemsData.len() == null)
      return null

    return res.__update({
      hasRewards = true
      crateItemsData
    })
  }))

  return {
    rendObj = ROBJ_SOLID
    size = [wndWidth, SIZE_TO_CONTENT]
    color = Color(9, 14, 25)
    children = [
      mkImage("ui/gameImage/daily_rewards_bg.jpg", { keepAspect = true })
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          mkDailyRewardsHeader(receivedData)
          mkDailyRewardsAnimation(receivedData)
          dailyRewardsHeader
          mkDailyRewardsContent(cratesCompWatch)
          mkButton(receivedData)
        ]
        transform = {}
        animations = mkMoveDownAnim()
      }
    ]
  }
}

let function open() {
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = @() null
    children = dailyRewards
  })
}

let function close() {
  removeModalWindow(WND_UID)
}

let checkOpenDebounced = debounce(function() {
  if (canDisplayOffers.value && (dailyRewardsUnlock.value?.hasReward ?? false))
    isOpened(true)
}, 0.01)

checkOpenDebounced()
foreach (v in [canDisplayOffers, dailyRewardsUnlock])
  v.subscribe(@(_) checkOpenDebounced())

isOpened.subscribe(@(v) v ? open() : close())
if (isOpened.value)
  open()

console_register_command(@() isOpened(true), "ui.openDailyRewards")

return {
  isOpened
}
