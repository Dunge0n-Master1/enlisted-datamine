from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { perksData } = require("%enlist/soldiers/model/soldierPerks.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let {
  tierText, levelBlockWithProgress, kindIcon, classIcon, classNameColored,
  classTooltip, rankingTooltip, mkSoldierMedalIcon
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let {  gap, noteTxtColor, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkSoldiersData } = require("%enlist/soldiers/model/collectSoldierData.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")

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
      color = defTxtColor
      text = " ({0})".subst(loc("bonusExp/short", { value = $"+{bonus}" }))
    }, sub_txt),
    @() loc("tooltip/soldierExpBonus"))
}

let callnameBlock = @(callname, soldierName) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  halign = ALIGN_LEFT
  clipChildren = true
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.Marquee
      delay = 1
      speed = 50
      rendObj = ROBJ_TEXT
      text = callname
      color = noteTxtColor
    }.__update(h2_txt)
    {
      size = [flex(), SIZE_TO_CONTENT]
      key = "soldierName_small"
      rendObj = ROBJ_TEXT
      text = soldierName
      color = noteTxtColor
      padding = [0, 0, hdpx(2), 0]
    }.__update(sub_txt)
  ]
}


let nameField = function(soldierWatch){
  let soldierName = getObjectName(soldierWatch.value)
  let { callname = "" } = soldierWatch.value
  return @(){
    flow = FLOW_HORIZONTAL
    watch = soldierWatch
    size = [flex(), SIZE_TO_CONTENT]
    gap = hdpx(5)
    children = [
      callname != "" ? callnameBlock(callname, soldierName)
      : {
          size = [flex(), SIZE_TO_CONTENT]
          key = "soldierName_big"
          rendObj = ROBJ_TEXT
          text = soldierName
          color = noteTxtColor
        }.__update(h2_txt)
    ]
  }
}

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
    let medal = mkSoldierMedalIcon(soldierWatch.value, hdpx(24))
    return {
      watch = [soldierWatch, needFreemiumStatus]
      size = [flex(), (soldierWatch.value?.callname ?? "") != "" ? hdpx(82) : hdpx(65)]
      flow = FLOW_VERTICAL
      animations = hdrAnimations
      transform = {}
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_TOP
          gap = gap
          children = [
            withTooltip({
              flow = FLOW_HORIZONTAL
              valign = ALIGN_TOP
              gap = gap
              size = [flex(), SIZE_TO_CONTENT]
              children = [
                tierText(tier).__update(h2_txt)
                nameField(soldierWatch)
              ]
            }, @() rankingTooltip(tier))
            medal == null ? null : withTooltip(medal, @() loc("hero/medal"))
            levelBlockWithProgress(
              soldierWatch,
              perksWatch,
              needFreemiumStatus.value,
              {padding = [hdpx(4), 0, 0, 0]}
            )
          ]
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = gap
              valign = ALIGN_CENTER
              children = [
                withTooltip({
                    flow = FLOW_HORIZONTAL
                    gap = gap
                    valign = ALIGN_CENTER
                    children = [
                      kindIcon(sKind, hdpx(30), sClassRare)
                      classIcon(armyId, sClass, hdpx(30))
                      classNameColored(sClass, sKind, sClassRare)
                    ]
                  },
                  @() classTooltip(armyId, sClass, sKind))
                mkClassBonus(classBonusWatch)
              ]
            }
          ]
        }
      ]
    }
  }
}

return mkNameBlock