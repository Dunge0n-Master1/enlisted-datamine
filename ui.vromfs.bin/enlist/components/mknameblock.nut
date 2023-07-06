from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { perksData } = require("%enlist/soldiers/model/soldierPerks.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let {
  tierText, kindIcon, classIcon, classNameColored, levelBlock, experienceTooltip,
  classTooltip, rankingTooltip, mkSoldierMedalIcon, calcExperienceData
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { gap, bigPadding, smallPadding, noteTxtColor, defTxtColor, msgHighlightedTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { panelBgColor } = require("%enlSqGlob/ui/designConst.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkSoldiersData } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { perkLevelsGrid } = require("%enlist/meta/perks/perksExp.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")


let hdrAnimations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic, trigger = "hdrAnim"}
  { prop = AnimProp.translate, from =[-hdpx(70), 0], to = [0, 0], duration = 0.15, easing = OutQuad, trigger = "hdrAnim"}
]

let mkClassBonus = @(classBonusWatch) function() {
  let res = { watch = classBonusWatch }
  let bonus = 100 * classBonusWatch.value
  if (bonus == 0)
    return res
  return withTooltip(res.__update({
      rendObj = ROBJ_TEXT
      color = msgHighlightedTxtColor
      text = loc("bonusExp/short", { value = $"+{bonus}" })
    }, sub_txt),
    @() loc("tooltip/soldierExpBonus"))
}

let callnameBlock = @(callname) {
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
  delay = 1
  speed = 50
  rendObj = ROBJ_TEXT
  text = callname
  color = noteTxtColor
}.__update(body_txt)

let nameField = function(soldierWatch) {
  return function(){
    let { callname = "" } = soldierWatch.value
    return {
      flow = FLOW_HORIZONTAL
      watch = soldierWatch
      size = [flex(2), SIZE_TO_CONTENT]
      gap
      children = [
        callname != "" ? callnameBlock(callname)
        : {
            size = [flex(), SIZE_TO_CONTENT]
            key = "soldierName_big"
            rendObj = ROBJ_TEXT
            text = getObjectName(soldierWatch.value)
            color = noteTxtColor
          }.__update(body_txt)
      ]
    }
  }
}

let levelBlockWithProgress = @(
  soldierWatch, perksWatch, isFreemiumMode = false, thresholdColor = 0, override = {}
) function() {
  let res = { watch = [soldierWatch, perksWatch, perkLevelsGrid] }
  let { guid = null, tier = 1 } = soldierWatch.value
  if (guid == null)
    return res
  let levelData = calcExperienceData(soldierWatch.value.__merge(perksWatch.value ?? {}), perkLevelsGrid.value.expToLevel)
  let { maxLevel, exp, expToNextLevel, perksCount, perksLevel } = levelData
  let expProgress = expToNextLevel > 0 ? 100.0 * exp / expToNextLevel : 0
  let isMaxed = perksLevel == maxLevel
  return withTooltip(res.__update({
      key = guid
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = gap
      children = [
        levelBlock({
          curLevel = perksCount
          leftLevel = max(perksLevel - perksCount, 0)
          lockedLevel = max(maxLevel - perksLevel, 0)
          hasLeftLevelBlink = true
          guid = guid
          fontSize = isMaxed ? hdpx(16) : hdpx(12)
          isFreemiumMode = isFreemiumMode
          thresholdColor
          tier = tier
        }).__update({minWidth = hdpx(120), halign = ALIGN_CENTER})
        isMaxed ? null : {
          size = [flex(), hdpx(5)]
          minWidth = hdpx(120)
          children = [
            { size = flex(), rendObj = ROBJ_SOLID, color = Color(154, 158, 177) }
            { size = [pw(expProgress), flex()], rendObj = ROBJ_SOLID,  color = Color(47, 137, 211) }
          ]
        }
      ]
    }).__update(override),
    @() experienceTooltip(levelData))
}

let mkSoldierNameSmall = @(soldier)
  (soldier?.callname ?? "") == "" ? null : {
    size = SIZE_TO_CONTENT
    key = "soldierName_small"
    rendObj = ROBJ_TEXT
    text = getObjectName(soldier)
    color = defTxtColor
    padding = [0, smallPadding * 2]
  }.__update(sub_txt)


let iconSize = hdpx(26)
let medalSize = hdpx(24)

let function mkNameBlock(soldier) {
  let soldierWatch = mkSoldiersData(soldier)
  let perksWatch = Computed(@() clone perksData.value?[soldier.value?.guid])
  let classBonusWatch = Computed(function() {
    let soldierV = soldier.value
    if (soldierV == null)
      return 0
    return armyEffects.value?[getLinkedArmyName(soldierV)].class_xp_boost[soldierV.sClass] ?? 0
  })
  return function() {
    let {armyId = null, sClass = null, sKind = null, sClassRare = 0, tier = 1} = soldierWatch.value
    let medal = mkSoldierMedalIcon(soldierWatch.value, medalSize)
    let isPremium = getClassCfg(sClass)?.isPremium ?? false

    let classTooltipCb = @() classTooltip(armyId, sClass, sKind)
    return {
      watch = [soldierWatch, campPresentation, needFreemiumStatus]
      size = [flex(), hdpx(70)]
      animations = hdrAnimations
      transform = {}
      rendObj = ROBJ_SOLID
      color = panelBgColor
      children = [
        isPremium ? classIcon(armyId, sClass, iconSize) : null
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          padding = [0, bigPadding]
          children = [
            {
              size = flex()
              flow = FLOW_VERTICAL
              children = [
                {
                  size = [flex(), ph(40)]
                  flow = FLOW_HORIZONTAL
                  gap
                  padding = [0, 0, 0, isPremium ? iconSize : 0]
                  valign = ALIGN_CENTER
                  children = [
                    withTooltip(kindIcon(sKind, medalSize, sClassRare), classTooltipCb)
                    withTooltip(classNameColored(sClass, sKind, sClassRare), classTooltipCb)
                    withTooltip(tierText(tier).__update({ color = defTxtColor }, sub_txt),
                      @() rankingTooltip(tier))
                    mkSoldierNameSmall(soldierWatch.value)
                  ]
                }
                {
                  size = flex()
                  flow = FLOW_HORIZONTAL
                  gap
                  valign = ALIGN_CENTER
                  children = [
                    isPremium ? null : classIcon(armyId, sClass, hdpx(30))
                    nameField(soldierWatch)
                    medal == null ? null : withTooltip(medal, @() loc("hero/medal"))
                  ]
                }
              ]
            }
            {
              size = [SIZE_TO_CONTENT, flex()]
              flow = FLOW_VERTICAL
              halign = ALIGN_RIGHT
              children = [
                {
                  size = [SIZE_TO_CONTENT, ph(40)]
                  valign = ALIGN_CENTER
                  children = mkClassBonus(classBonusWatch)
                }
                {
                  size = [SIZE_TO_CONTENT, flex()]
                  valign = ALIGN_CENTER
                  children = levelBlockWithProgress(
                    soldierWatch,
                    perksWatch,
                    needFreemiumStatus.value,
                    campPresentation.value?.color
                  )
                }
              ]
            }
          ]
        }
      ]
    }
  }
}

return mkNameBlock