from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { sound_play } = require("sound")
let { mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let { progressBar, txt, noteTextArea
} = require("%enlSqGlob/ui/defcomps.nut")
let { soldierLvlColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkArmyResultExpTooltip
} = require("%enlist/debriefing/components/mkArmyExpTooltip.nut")
let cursors = require("%ui/style/cursors.nut")

const trigger = "content_anim"

let ADD_EXP_TIME = 0.6
let COMPLETED_TIME = 0.9
let REWARD_BLOCK_WIDTH = hdpx(300)
let REWARD_ICON_SIZE = hdpx(50)

let wrapParams = @(width) {
  halign = ALIGN_CENTER
  width
  hGap = fsh(5)
  vGap = fsh(5)
}

let getGlobalGiftGuid = @(gift, campaignId = null) (campaignId ?? "") != ""
  ? $"progress_gift_{campaignId}_{gift.basetpl}"
  : $"progress_gift_{gift.army}_{gift.basetpl}"

let getNextGlobalGiftRequire = @(gift, cycle)
  cycle > 0 ? gift.loopExp : gift.startExp

let getNextGlobalGiftCount = @(gift, cycle)
  cycle > 0 ? gift.loopCount : gift.startCount

let function mkGiftView(giftCfg) {
  let itemCurrency = getCurrencyPresentation(giftCfg.basetpl)
  if (itemCurrency != null)
    return mkCurrencyImage(itemCurrency.icon, [REWARD_ICON_SIZE, REWARD_ICON_SIZE])

  return null
}

let mkShowAnim = @(duration) [
  { prop = AnimProp.opacity, from = 1, to = 1, duration = duration,
    play = true, easing = InOutCubic, trigger }
]

let mkHideAnim = @(duration) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = duration,
    play = true, easing = InOutCubic, trigger }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3,
    play = true, delay = duration, easing = InOutCubic, trigger }
]

let mkExpTooltip = @(squads, exp, details, isDeserter, armyId)
  mkArmyResultExpTooltip(squads, exp, details, isDeserter, armyId)

let mkGift = kwarg(function(gift, giftCfg, addExp, mkAppearAnimations, animDelay, tooltip, onFinish) {
  let wasExp = gift?.exp ?? 0
  local cycle = gift?.cycle ?? 0
  local exp = wasExp + addExp
  local count = 0

  let nextGiftExp = getNextGlobalGiftRequire(giftCfg, cycle)
  let nextGiftCount = getNextGlobalGiftCount(giftCfg, cycle)
  local hasCompleted = false
  while (true) {
    let nextReq = getNextGlobalGiftRequire(giftCfg, cycle)
    if (nextReq > exp)
      break

    hasCompleted = true
    count += getNextGlobalGiftCount(giftCfg, cycle)
    exp -= nextReq
    cycle ++
  }

  return {
    size = [REWARD_BLOCK_WIDTH, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        behavior = Behaviors.Button
        onHover = @(on) cursors.setTooltip(on ? tooltip : null)
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            children = [
              hasCompleted
                ? noteTextArea({
                    text = loc("rewardReceived")
                    color = soldierLvlColor
                    halign = ALIGN_CENTER
                    animations = mkHideAnim(animDelay + COMPLETED_TIME)
                  }.__update(sub_txt))
                : null
              noteTextArea({
                text = loc("nextReward")
                halign = ALIGN_CENTER
                opacity = hasCompleted ? 0 : 1
                animations = hasCompleted
                  ? mkShowAnim(animDelay + COMPLETED_TIME)
                  : null
              }.__update(sub_txt))
            ]
          }
          {
            size = [flex(), SIZE_TO_CONTENT]
            children = [
              progressBar({
                value = nextGiftExp <= 0 ? 0 : 1.0 * wasExp / nextGiftExp
                addValue = nextGiftExp <= 0 ? 0 : 1.0 * addExp / nextGiftExp
                color = Color(150,150,150)
                addValueAnimations = [
                  { prop = AnimProp.scale, from = [0, 1], to = [0, 1], play = true,
                    duration = animDelay + ADD_EXP_TIME, trigger }
                  { prop = AnimProp.scale, from = [0, 1], to = [1, 1], play = true,
                    duration = ADD_EXP_TIME, easing = OutCubic, delay = animDelay + ADD_EXP_TIME,
                    trigger, onFinish }
                ]
              })
              hasCompleted
                ? {
                    rendObj = ROBJ_SOLID
                    size = flex()
                    margin = [smallPadding, 0]
                    color = soldierLvlColor
                    animations = mkHideAnim(animDelay + COMPLETED_TIME)
                  }
                : null
            ]
          }
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_BOTTOM
        children = [
          mkGiftView(giftCfg)
          txt($"x{max(nextGiftCount, count)}")
        ]
      }.__update(!hasCompleted ? {}
        : {
            transform = { pivot = [0, 0.5] }
            animations = [{
              prop = AnimProp.scale, from = [1.2,1.2], to = [1,1],
              duration = 1.4, play = true, loop = true, easing = CosineFull
            }]
          })
    ]
    transform = {}
    animations = mkAppearAnimations(animDelay, @() sound_play("ui/debriefing/new_equip"))
  }
})

let function mkRewardsProgress(
  giftsConfig, curGifts, addExp, mkAppearAnimations, armyId, campaignId, armyExpDetailed,
  squads, result, onFinish, blockWidth
) {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    children = wrap(giftsConfig.map(@(giftCfg, idx) mkGift({
      gift = curGifts?[getGlobalGiftGuid(giftCfg, campaignId)]
      giftCfg, addExp, mkAppearAnimations,
      animDelay = idx * 0.5,
      tooltip = mkExpTooltip(squads, addExp, armyExpDetailed, result?.deserter ?? false, armyId)
      onFinish = idx == giftsConfig.len() - 1 ? onFinish : null
    })), wrapParams(blockWidth))
  }
}

return kwarg(mkRewardsProgress)
