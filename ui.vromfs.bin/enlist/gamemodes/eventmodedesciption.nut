from "%enlSqGlob/ui_library.nut" import *

let { fontSub, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { selEvent, selLbMode, selEventEndTime, inactiveEventsToShow } = require("eventModesState.nut")
let { isWide, bigPadding, accentTitleTxtColor, maxContentWidth, defTxtColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { verticalGap, localPadding, localGap, armieChooseBlockWidth, eventBlockWidth
} = require("eventModeStyle.nut")
let { startBtnWidth, mkTimerIcon } = require("%enlSqGlob/ui/designConst.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { mkRewardImages, prepareRewards, mkRewardTooltip, rewardWidthToHeight, mkSeasonTime,
  mkRewardText
} = require("%enlist/battlepass/rewardsPkg.nut")
let rewardsItemMapping = require("%enlist/items/itemsMapping.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { eventRewardsUnlocks, lbRewards, lbRewardsTypes } = require("eventRewardsState.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { cardCountCircleSmall } = require("%enlist/battlepass/bpPkg.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { mkWindowHeader } = require("eventModesPkg.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkMedalCard } = require("%enlist/profile/medalsPkg.nut")
let { curLbIdx } = require("%enlist/leaderboard/lbState.nut")
let { availPortraits, availNickFrames } = require("%enlist/profile/decoratorState.nut")
let { medals } = require("%enlist/meta/profile.nut")

let sizeCard    = [hdpx(138), hdpx(138)]
let imageHeight = hdpx(138)
let imageSize   = [rewardWidthToHeight * imageHeight, imageHeight]
let descritionBlockWidth = Computed(@()
  min(sw(100) - safeAreaBorders.value[1] - safeAreaBorders.value[3], maxContentWidth)
  - armieChooseBlockWidth - startBtnWidth - eventBlockWidth - bigPadding * 3 - localPadding * 2)
let isEnded = Computed(@() inactiveEventsToShow.value.contains(selEvent.value) &&
  (selEvent.value?.leaderboardTableIdx ?? curLbIdx.value) < curLbIdx.value )

let participationRewards = Computed(function() {
  let unlocks = []
  let lbRew = clone lbRewards.value
  let localization = {
    description = "events/endGiven"
  }
  let currentEvent = selLbMode.value
  lbRew?[currentEvent].each(@(val) val.stages.each(function(v) {
    if (v.progress == 100) {
      val.localization <- localization
      unlocks.append(val)
    }
  }))
  if (unlocks.len() == 0)
    return {}
  return { [currentEvent] = unlocks }
})

let shadowParams = {
  fontFx = FFT_BLUR
  fontFxColor = Color(0,0,0,50)
  fontFxFactor = min(64, hdpx(64))
  fontFxOffsY = hdpx(0.9)
}

let function eventsTimer() {
  let res = { watch = [selEventEndTime, serverTime, isEnded] }
  if (isEnded.value || selEventEndTime.value - serverTime.value <= 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    padding = bigPadding
    vplace = ALIGN_BOTTOM
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("bp/timeLeft")
        color = accentTitleTxtColor
      }.__update(fontSub, shadowParams)
      mkSeasonTime(selEventEndTime.value - serverTime.value, shadowParams)
    ]
  })
}


let infoBlock = @() {
  rendObj = ROBJ_TEXTAREA
  watch = selEvent
  size = [flex(), SIZE_TO_CONTENT]
  margin = isWide ? [0, hdpx(100),0,0] : 0
  behavior = Behaviors.TextArea
  text = selEvent.value?.description
}

let completedRewardSign = {
  size = [hdpx(28), hdpx(28)]
  pos = [0, -hdpx(28)]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = Color(0,0,0)
  hplace = ALIGN_CENTER
  children = faComp("check", { fontSize = hdpx(15) })
}

let completedRewardSignBottom = completedRewardSign.__merge({
  pos = [0, hdpx(9)]
  vplace = ALIGN_BOTTOM
})

let mkRewardTitle = @(text, isCompleted) {
  children = [
    isCompleted ? completedRewardSign : null
    {
      size = [sizeCard[0], SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text
    }
  ]
}

let mkRewardsBlockTitle = @(text) {
  rendObj = ROBJ_TEXT
  halign = ALIGN_CENTER
  text
}.__update(fontBody)

let function temporarySign() {
  let size = hdpxi(24)
  return{
    rendObj = ROBJ_IMAGE
    size = [size, size]
    color = Color(0,0,0)
    image = Picture($"!ui/uiskin/battlepass/Ellipse.svg:{size}:{size}:K")
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    margin = smallPadding
    children = mkTimerIcon(size, { color = accentTitleTxtColor })
  }
}

let extraRewardText = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = loc("includingRewardsBelow")
  color = defTxtColor
}.__update(fontSub)

let function mkReward(rewardData, hasReceived = false) {
  let {count, reward} = rewardData
  local rewardToShow = mkRewardImages(reward, imageSize)
    ?? mkRewardText(reward, hdpx(60), {size = sizeCard})
  if (rewardData.reward?.stackImages != null) {
    let r = rewardData.reward
    rewardToShow = mkMedalCard(r.bgImage, r.stackImages, hdpx(138))
  }
  return {
    size = sizeCard
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      withTooltip(rewardToShow, @() mkRewardTooltip(reward))
      hasReceived ? completedRewardSignBottom : null
      count > 1 ? cardCountCircleSmall(count) : null
      reward?.isTemporary ? temporarySign : null
    ]
  }
}

let mkProgress = @(current, required) required <= 1 || current == required ? null : {
  rendObj = ROBJ_TEXT
  text = $"{current} / {required}"
  color = accentTitleTxtColor
}.__update(fontSub)

let rewardsWrapParams = {
  width = descritionBlockWidth.value
  vGap = localGap
  hGap = localGap
}

let function mkTasksBlock(
  unlocks, rewardType = null, mkChild = @(_) null, rewardExtraObj = null, isLastType = false
) {
  unlocks = unlocks ?? []
  let totalUnlocks = unlocks.len()
  if (rewardType == null)
    unlocks = clone unlocks
      .map(@(v) v.__merge({ maxProgress =
        v.stages.reduce(@(res, val) val.progress > res ? val.progress : res, 0) }))
      .sort(@(a, b) a.maxProgress <=> b.maxProgress)

  return function() {
    let rewardsChildren = []
    foreach (uIdx, unlock in unlocks) {
      let { stages = [], current = 0, required = 0 } = unlock
      let totalStages = stages.len()
      foreach (sIdx, stage in stages) {
        if ((rewardType != null && unlock.name != rewardType)
          || (rewardType != null && stage.progress == 100))
          continue
        let curStageReward = (stage?.rewards.keys()[0] ?? stage?[0].rewards.keys()[0]) ?? ""
        let curRewardGuid = rewardsItemMapping.value?[curStageReward].medals[0]
          ?? rewardsItemMapping.value?[curStageReward].decorators[0].guid

        let hasReceived = curRewardGuid in availPortraits.value
          || medals.value.findindex(@(v) v.id == curRewardGuid) != null
          || curRewardGuid in availNickFrames.value

        let isLast = isLastType && uIdx == totalUnlocks - 1 - participationRewards.value.len()
          && sIdx == totalStages - 1
        let rewards = prepareRewards(stage?.rewards ?? {}, rewardsItemMapping.value)
          .sort(@(a,b) (b?.reward.medals.len() ?? 0) <=> (a?.reward.medals.len() ?? 0)
            || (a?.reward.cardText ?? "") <=> (b?.reward.cardText ?? "")
            || (a?.reward.isTemporary ?? false) <=> (b?.reward.isTemporary ?? false))
        let rewardCards = rewards.map(@(r) mkReward(r, hasReceived))
        let rchildren = {
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = bigPadding
          children = [
            mkChild?(stage?.progress)
            {
              flow = FLOW_HORIZONTAL
              gap = localGap
              children = rewardType != null
                ? wrap(rewardCards, rewardsWrapParams)
                : rewardCards
            }
            unlock?.localization.description != null
              ? mkRewardTitle(loc(unlock?.localization.description), unlock?.isCompleted ?? false)
              : null
            isLast ? null : rewardExtraObj
            mkProgress(current, required)
          ]
        }
        rewardsChildren.append(rchildren)
      }
    }

    return {
      watch = [descritionBlockWidth, rewardsItemMapping, participationRewards,
        availPortraits, medals, availNickFrames]
      flow = rewardType == null ? FLOW_HORIZONTAL : FLOW_VERTICAL
      gap = rewardType == null ? localGap : verticalGap
      children = rewardsChildren
    }
  }
}

let eventsProgressChild = @(progress, rType) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = rType != "tillPercent" ? loc("events/getTop", {progress})
    : progress == 100 ? loc("events/participationReward")
    : $"{loc("events/getTop", {progress})}%"
}.__update(fontBody)


let function rewardsBlock() {
  let lbTotal = lbRewardsTypes.len()
  return {
    watch = [participationRewards, eventRewardsUnlocks, lbRewards,
      selLbMode, inactiveEventsToShow, isEnded]
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = verticalGap
    children = [
      {
        flow = FLOW_VERTICAL
        gap = localGap
        children = [
          !isEnded.value
          && (participationRewards.value.len() > 0 || (eventRewardsUnlocks.value?[selLbMode.value] ?? []).len() > 0)
              ? mkRewardsBlockTitle(loc("events/participationReward"))
              : null
          isEnded.value ? null :{
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = localGap
            children = [
              mkTasksBlock(participationRewards.value?[selLbMode.value])
              mkTasksBlock(eventRewardsUnlocks.value?[selLbMode.value])
            ]
          }
        ]
      }
    ].extend(lbRewardsTypes
      .map(@(rType, idx)
        mkTasksBlock(lbRewards.value?[selLbMode.value], rType,
          @(progress) eventsProgressChild(progress, rType),
          extraRewardText, idx == lbTotal - 1)
      ))
  }
}

let eventDescription = makeVertScroll({
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = localPadding
  children = [
    infoBlock
    rewardsBlock
  ]
})

let function eventModeDescription() {
  let { locId = null, image = null } = selEvent.value
  return {
    watch = [descritionBlockWidth, selEvent]
    flow = FLOW_VERTICAL
    gap = bigPadding
    size = [descritionBlockWidth.value, flex()]
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          mkWindowHeader(loc(locId), image)
          eventsTimer
        ]
      }
      eventDescription
    ]
  }
}

return eventModeDescription