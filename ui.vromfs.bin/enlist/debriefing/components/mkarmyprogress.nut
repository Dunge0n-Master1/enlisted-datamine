from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let progressBar = require("%enlist/components/progressBar.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { mkCurrencyImage, mkCurrencyTooltip } = require("%enlist/shop/currencyComp.nut")
let { sound_play } = require("sound")
let { mkArmyBaseExpTooltip, mkArmyPremiumExpTooltip, mkArmyResultExpTooltip
} = require("%enlist/debriefing/components/mkArmyExpTooltip.nut")
let { mkWinXpImage, mkBattleHeroAwardXpImage, mkPremiumAccountXpImage, mkPremiumSquadXpImage,
  mkBoosterXpImage, mkFreemiumXpImage
} = require("%enlist/debriefing/components/mkXpImage.nut")
let { bigPadding, activeTxtColor, progressBorderColor, progressExpColor,
  progressAddExpColor, defBgColor, activeBgColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let { mkXpBooster } = require("%enlist/components/mkXpBooster.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")

const trigger = "content_anim"
const playerCountMultTooltipText = "debriefing/playerCountMultArmyExpTooltip"
const notEnoughPlayersShortText = "debriefing/playerCountMultArmyExpTooltipShort"

let awardPositiveColor = Color(252, 186, 3, 255)
let awardNegativeColor = Color(252, 0, 0, 255)

let PROGRESS_ANIM_DELAY = 2.0
let AWARD_ANIM_DELAY = 0.3

let lvlWidth = sw(20)
let lineHeight = hdpx(30)
let slotHeight = hdpx(70)
let ticketHeight = hdpx(40)
let xpIconSize = hdpx(50)

let mkSign = @(text) txt({ text, padding = hdpx(5) })
let multiplySign = mkSign("\u00D7")
let addingSign = mkSign("+")
let freemiumResultImage = mkFreemiumXpImage(xpIconSize)
let txtWithPad = @(text) txt({text, padding=hdpx(5)})
let expGainedText = txt(" {0}{1}".subst(loc("debriefing/expAdded"), loc("ui/colon")))

let mkLevelTextBlock = @(lvl, lvlAlign, mkText = @(baseText) baseText) {
  size = [lvlWidth, flex()]
  halign = lvlAlign
  hplace = lvlAlign
  valign = ALIGN_CENTER
  children = [
    mkText(txt({
      text = loc("levelInfo", { level = lvl })
      color = activeTxtColor
      padding = [0, hdpx(10)]
    }))
    {
      rendObj = ROBJ_SOLID
      size = [hdpx(1), flex()]
      color = progressBorderColor
    }
  ]
}

let premiumAccAndSquadIcon = @(size, armyId) {
  size = [size * 1.5, size]
  children = [
    mkPremiumSquadXpImage(size, armyId).__update({pos=[size * 0.5, 0]})
    mkPremiumAccountXpImage(size)
  ]
}
let function premiumIcon(size, armyId, isPremiumAccount, isPremiumSquad) {
  if (isPremiumAccount && isPremiumSquad)
    return premiumAccAndSquadIcon(size, armyId)
  if (isPremiumAccount)
    return mkPremiumAccountXpImage(size)
  if (isPremiumSquad)
    return mkPremiumSquadXpImage(size, armyId)
  return null
}

let function mkValueWithIcon(value, icon) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      txt(value)
      icon
    ]
  }
}

let mkValueWithIconArmyExp = @(value, icon, textLocId = null) mkValueWithIcon(
  {
    text = textLocId == null ? value : $"{value} {loc(textLocId)}",
    color = value >= 1.0 ? awardPositiveColor : awardNegativeColor
  }
  icon
)

let horFlow = @(children) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children
}

let function mkArmyExpDetailed(result, details, armyAddExp, squads, armyId) {
  if (armyAddExp <= 0)
    return []

  let { baseArmyExp = 0, boostedExp = 0, premiumExp = 0, noviceBonus = 0,
    battleResultMult = 1.0, battleHeroAwardsMult = 1.0, playerCountMult = 1.0, armyExpBoost = 0,
    isBattleResultMultDisabled = false, isArmyBoostDisabled = false,
    isBattleHeroMultDisabled = false, freemiumExpMult = 1.0
  } = details

  let isSuccess = (result?.success ?? false)
  let isDeserter = (result?.deserter ?? false)

  let battleResultLocId = isSuccess ? "debriefing/battleResultWinMult"
                          : isDeserter ? "debriefing/battleResultDeserterMult"
                          : "debriefing/battleResultMult"
  let battleResultText = isDeserter ? "debriefing/battleResultDeserterMultShort" : null
  let battleResultImage = isSuccess ? mkWinXpImage(xpIconSize) : null


  let hasBoostBonus = boostedExp > 0
  let hasPremBonus = premiumExp > 0
  let hasPremiumAccount = (details?.premiumExpMul ?? 1.0) > 1.0
  let hasPremiumSquad = squads.findvalue(@(squad) (squad?.premSquadExpBonus ?? 0) > 0) != null
  let hasBattleResultMult = battleResultMult != 1.0
  let hasBattleHeroMult = battleHeroAwardsMult != 1.0
  let hasPlayerCountMultIcon = playerCountMult != 1.0
  let hasFreemiumMult = freemiumExpMult != 1.0
  let needsParentheses = (hasBoostBonus || hasPremBonus)
    && (hasBattleResultMult || hasBattleHeroMult || hasFreemiumMult)
  let showNotEnoughPlayersNotice = hasPlayerCountMultIcon || isBattleResultMultDisabled
    || isArmyBoostDisabled || isBattleHeroMultDisabled
  let showDetailed = hasBattleHeroMult || hasBattleResultMult || showNotEnoughPlayersNotice
    || hasPremBonus || hasBoostBonus || hasFreemiumMult || noviceBonus > 0

  let baseExp = showDetailed
    ? withTooltip(txt(baseArmyExp), @() mkArmyBaseExpTooltip(squads, baseArmyExp))
    : null
  let boostExp = !hasBoostBonus ? null
    : horFlow([
        addingSign
        withTooltip(
          mkValueWithIconArmyExp(boostedExp, mkBoosterXpImage(xpIconSize))
          @() loc("debriefing/boosterBonusExp", { percent = colorize(awardPositiveColor, 100 * armyExpBoost) }))
      ])
  let premExp = !hasPremBonus ? null
    : horFlow([
        addingSign
        withTooltip(
          mkValueWithIconArmyExp(premiumExp, premiumIcon(xpIconSize, armyId, hasPremiumAccount, hasPremiumSquad))
          @() mkArmyPremiumExpTooltip(squads, premiumExp, details, armyId, hasPremiumAccount, hasPremiumSquad))
      ])
  let battleResultMultIcon = !hasBattleResultMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(battleResultMult, battleResultImage, battleResultText)
          @() loc(battleResultLocId))
      ])
  let freemiumResultMultIcon = !hasFreemiumMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(freemiumExpMult, freemiumResultImage)
          @() loc("debriefing/freemExpBonus"))
      ])
  let battleHeroMultIcon = !hasBattleHeroMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(battleHeroAwardsMult, mkBattleHeroAwardXpImage(xpIconSize))
          @() loc("debriefing/battleHeroAwardsMult"))
      ])
  let playerCountMultIcon = !showNotEnoughPlayersNotice ? null
    : horFlow([
        hasPlayerCountMultIcon ? multiplySign : null
        withTooltip(
          hasPlayerCountMultIcon
            ? mkValueWithIconArmyExp(playerCountMult, null, notEnoughPlayersShortText)
            : txt({text=loc(notEnoughPlayersShortText), color = awardNegativeColor}),
          @() loc(playerCountMultTooltipText))
      ])
  let noviceBonusExp = noviceBonus <= 0 ? null
    : horFlow([
        addingSign
        withTooltip(txt(noviceBonus), @() loc("debriefing/noviceExpBonus"))
      ])
  let resultExp = withTooltip(
    txt({text=armyAddExp, color=awardPositiveColor}.__update(body_txt))
    @() mkArmyResultExpTooltip(squads, armyAddExp, details, isDeserter, armyId))

  return showDetailed
    ? [
        expGainedText
        needsParentheses ? txt("(") : null
        baseExp
        boostExp
        premExp
        needsParentheses ? txt(")") : null
        battleResultMultIcon
        freemiumResultMultIcon
        battleHeroMultIcon
        playerCountMultIcon
        noviceBonusExp
        txtWithPad("=")
        resultExp
      ]
    : [
        expGainedText
        resultExp
      ]
}

let mkLevelsGrid = @(lvl, armyAddExp, result, armyExpDetailed, squads, armyId) {
  size = [flex(), xpIconSize + bigPadding]
  children = [
    mkLevelTextBlock(lvl, ALIGN_LEFT,
      @(baseText) {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          baseText
        ].extend(mkArmyExpDetailed(result, armyExpDetailed, armyAddExp, squads, armyId))
      })
    mkLevelTextBlock(lvl + 1, ALIGN_RIGHT)
  ]
}

let mkLevelRewardAnim = @(animDelay, onFinish = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
    easing = InOutCubic, trigger }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.8, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.8, play = true,
    easing = OutQuart, delay = animDelay, trigger, onFinish }
]

let rewardStyle = {
  rendObj = ROBJ_BOX
  size = [fsh(40), fsh(30)]
  flow = FLOW_VERTICAL
  padding = fsh(4)
  fillColor = defBgColor
  borderColor = activeBgColor
  borderWidth = hdpx(1)
  transform = {}
  animations = mkLevelRewardAnim(0)
}

let mkSquadReward = @(squadCfg, level) {
  key = "squads"
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("levelReward/title", { level })
      color = activeTxtColor
      hplace = ALIGN_CENTER
    }.__update(body_txt)
    {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        mkSquadIcon(squadCfg?.icon, { size = [slotHeight, slotHeight] })
          .__update({ margin = [0,0,fsh(1),0] })
        txt(loc(squadCfg?.nameLocId ?? ""))
        txt({
          text = loc(squadCfg?.titleLocId ?? "")
          color = Color(200, 150, 100)
        })
      ]
    }
  ]
}.__update(rewardStyle)

local function mkSquadUnlock(gainLevel, squadCfg, armyId, animDelay, onFinish, gainRewardContent) {
  squadCfg = squadCfg.__merge(squadsPresentation?[armyId]?[squadCfg?.squadId] ?? {})
  let { nameLocId = "", titleLocId = "", icon = null } = squadCfg
  return withTooltip({
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    padding = [bigPadding, 0, 0, 0]
    children = [
      mkSquadIcon(icon, { size = [slotHeight, slotHeight] })
      {
        minWidth = fsh(25)
        flow = FLOW_VERTICAL
        children = [
          nameLocId == "" ? null : txt(loc(nameLocId))
          titleLocId == "" ? null : {
            size = [flex(), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc(titleLocId)
            color = Color(200, 150, 100)
          }.__update(sub_txt)
        ]
      }
    ]
    transform = {}
    animations = gainLevel != null
      ? [
          {
            prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
            trigger, onFinish = function() {
              gainRewardContent(mkSquadReward(squadCfg, gainLevel))
              sound_play("ui/debriefing/squad_progression_appear")
            }
          }
        ].extend(mkLevelRewardAnim(animDelay + 2, function() {
          onFinish?()
          sound_play("ui/debriefing/battle_result")
        }))
      : [
          {
            prop = AnimProp.opacity, from = 1, to = 1, duration = animDelay, play = true,
            trigger, onFinish
          }
        ]
  },
  @() loc("squads/squadUnlocked"))
}

let mkAwardGauge = @(maxValue, unlockRewards) {
  size = flex()
  children = unlockRewards.map(@(u) {
    size = [0, lineHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    pos = [pw(maxValue > 0 ? min(100.00 * (u.exp.tofloat() / maxValue.tofloat()), 100) : 0), 0]
    children = u?.isNext == true
      ? {
        rendObj = ROBJ_SOLID
        size = [hdpx(1), flex()]
        color = progressBorderColor
      }
      : faComp("caret-up", { fontSize = hdpx(10), pos = [0, hdpx(3)] })
  })
}

let mkProgress = kwarg(function(
  expToNextLevel, armyWasExp, armyAddExp, gainLevel, unlockRewards, hasNewLevel,
  details, squads, isDeserter, armyId, onFinishCb
) {
  let onFinish = function() {
    if (hasNewLevel)
      sound_play("ui/reward_receive")
    onFinishCb?()
  }
  return withTooltip({
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      progressBar({
        maxValue = expToNextLevel
        curValue = armyWasExp
        addValue = armyAddExp
        needText = true
        completeText = gainLevel != null
          ? loc("newLevelReached", { lvl = gainLevel }) : null
        hasBlink = gainLevel != null
        height = lineHeight
        addValueAnimations = [
          { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 1.0,
            play = true, trigger }
          { prop = AnimProp.scale, from = [0, 1], to = [1, 1], duration = 0.8,
            play = true, easing = OutCubic, delay = 1.0, trigger, onFinish }
        ]
        progressColor = progressExpColor
        addColor = progressAddExpColor
        addGauge = mkAwardGauge(expToNextLevel, unlockRewards)
      })
      {
        rendObj = ROBJ_BOX
        size = flex()
        borderColor = progressBorderColor
        borderWidth = hdpx(1)
      }
    ]
  },
  @() mkArmyResultExpTooltip(squads, armyAddExp, details, isDeserter, armyId))
})

let mkBaseAwardAnim = @(animDelay, onFinish) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay, play = true,
    easing = InOutCubic, trigger }
  { prop = AnimProp.opacity, from = 0, to = 0.5, duration = 0.3, play = true,
    easing = InOutCubic, trigger, delay = animDelay, onFinish}
]

let mkGainAwardAnim = @(animDelay) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay, trigger}
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.5, play = true,
    easing = InOutCubic, delay = animDelay, trigger }
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.5, play = true,
    easing = OutQuart, delay = animDelay, trigger }
  { prop = AnimProp.scale, from = [1,1], to = [1.4,1.4], duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay + 0.5, trigger }
  { prop = AnimProp.scale, from = [1.4,1.4], to = [1,1], duration = 0.3, play = true,
    easing = InOutCubic, delay = animDelay + 0.8, trigger }
]

let function mkAward(award, idx, maxValue, timeForRewards, onFinish) {
  let hasGained = !(award?.isNext ?? false)
  let xPos = maxValue > 0
    ? pw(min(100.00 * award.exp.tofloat() / maxValue.tofloat(), 100)) : 0

  let animDelay = AWARD_ANIM_DELAY * idx + PROGRESS_ANIM_DELAY + timeForRewards
  return {
    size = [0, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    pos = [xPos, 0]
    opacity = hasGained ? 1.0 : 0.5
    children = withTooltip(mkCurrencyImage(award.unlockId, [ticketHeight, ticketHeight]),
      @() mkCurrencyTooltip(award.unlockId))
    transform = {}
    animations = mkBaseAwardAnim(animDelay, onFinish)
      .extend(hasGained ? mkGainAwardAnim(animDelay) : [])
  }
}

let mkAwards = @(unlockRewards, maxValue, timeForRewards, onFinish) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [bigPadding, 0, 0, 0]
  children = unlockRewards.map(@(award, idx)
    mkAward(award, idx, maxValue, timeForRewards, idx == unlockRewards.len() - 1
      ? onFinish
      : null))
}

let mkGainAwards = @(unlockedRewards) {
  key = "awards"
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("receivedAwards")
      color = activeTxtColor
      hplace = ALIGN_CENTER
    }.__update(body_txt)
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = bigPadding
      valign = ALIGN_CENTER
      children = unlockedRewards.map(@(count, tpl) {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          txt({
            text = loc("common/amountShort", { count })
          }.__update(body_txt))
          mkCurrencyImage(tpl, ticketHeight * 1.5)
          txt(getItemName(tpl))
        ]
      }).values()
    }
  ]
}.__update(rewardStyle)

let mkExpBoosterWithTooltip = @(boosterType, value, locId) withTooltip(
  {
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_CENTER
    children = [
      mkXpBooster({ bType = boosterType }, { size = [hdpx(70), hdpx(86)] })
      {
        rendObj = ROBJ_TEXT
        text = loc("expBoost", { boost = (100.0 * value + 0.5).tointeger() })
      }
    ]
  }
  @() loc(locId, { percent = colorize(awardPositiveColor, 100 * value) }))

let function mkArmyProgress(
  armyId, armyWasLevel, armyWasExp, armyAddExp, progressCfg, unlockRewards,
  hasNewLevel, onFinish, gainRewardContent, result, armyExpDetailed = {}, squads = {},
  boosts = null
) {
  let levelGrid = progressCfg?.expToArmyLevel
  if (levelGrid == null)
    return null

  let expToNextLevel = levelGrid?[armyWasLevel] ?? levelGrid.top()
  let gainLevel = armyWasExp + armyAddExp >= expToNextLevel ? armyWasLevel + 1 : null
  let squadIndexToUnlock = (progressCfg?.lockedSquads ?? {}).findindex(@(s) s?.level == armyWasLevel + 1)
  let squadToUnlock = squadIndexToUnlock != null
    ? { squadId = squadIndexToUnlock }.__update(progressCfg?.lockedSquads[squadIndexToUnlock])
    : null

  let boostersOrder = [
    { val   = boosts?.soldier
      bType = "soldier",
      locId = "boostTotal/soldier"},
    { val   = boosts?.squad
      bType = "squad"
      locId = "boostTotal/squad"},
    { val   = boosts?.army
      bType = "army"
      locId = "boostTotal/army"}]

  let unlockedRewards = unlockRewards
    .filter(@(u) !(u?.isNext ?? false))
    .reduce(@(res, val)
      res.__update({[val.unlockId] = (res?[val.unlockId] ?? 0) + val.unlockCount}), {})

  let timeForRewards = unlockedRewards.len() > 0 ? 2 : 0
  let squadAnimDelay = AWARD_ANIM_DELAY * unlockRewards.len() + PROGRESS_ANIM_DELAY + timeForRewards
  let isDeserter = (result?.deserter ?? false)
  let mainContent = {
    size = [pw(90), SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = 2 * bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          mkLevelsGrid(armyWasLevel, armyAddExp, result, armyExpDetailed, squads, armyId)
          mkProgress({
            expToNextLevel
            armyWasExp
            armyAddExp
            gainLevel
            unlockRewards
            hasNewLevel
            details = armyExpDetailed
            squads
            isDeserter
            armyId
            onFinishCb = function() {
              if (unlockedRewards.len() > 0) {
                gainRewardContent(mkGainAwards(unlockedRewards))
                sound_play("ui/debriefing/squad_progression_appear")
              }
              if (unlockRewards.len() == 0 && squadToUnlock == null)
                onFinish?()
            }
          })
          mkAwards(unlockRewards, expToNextLevel, timeForRewards, squadToUnlock == null
            ? onFinish
            : null)
          squadToUnlock == null ? null
          : mkSquadUnlock(gainLevel, squadToUnlock, armyId, squadAnimDelay,
              onFinish, gainRewardContent)
        ]
      }
    ].extend(boostersOrder.map(@(booster) booster.val <= 0 ? null :
        mkExpBoosterWithTooltip(booster.bType, booster.val, booster.locId)))
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = mainContent
  }
}

return kwarg(mkArmyProgress)
