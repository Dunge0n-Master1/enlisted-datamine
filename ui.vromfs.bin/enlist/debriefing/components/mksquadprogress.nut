from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let cursors = require("%ui/style/cursors.nut")
let { sound_play } = require("sound")
let { progressBar, txt } = require("%enlSqGlob/ui/defcomps.nut")
let { mkSquadIcon, mkSquadPremIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let {
  gap, slotBaseSize, soldierLvlColor, smallPadding, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { combineMultispecialistAward } = require("%enlSqGlob/ui/battleHeroesAwards.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")
let { mkSquadExpTooltipText } = require("%enlist/debriefing/components/mkExpTooltipText.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")

const trigger = "content_anim"

let TIME_TO_NEXT_SQUAD = 0.5
let UNLOCK_ADD_EXP_TIME = 1.0

let squadCardSize = [slotBaseSize[0], hdpx(136)]

let colon = loc("ui/colon")

let squadIconStyle = {
  size = [hdpx(77), hdpx(77)]
  margin = [hdpx(3), 0, 0, 0]
}

let squadStatsCfg = [
  { stat = "awardScore", locId = "debriefing/score"},
].map(@(s) { toString = @(v) v.tostring() }.__update(s))

let function mkSquadTooltipText(squad, result) {
  let textList = squadStatsCfg.map(@(s)
    "".concat(loc(s.locId), colon, s.toString(squad?[s.stat] ?? s?.defaultValue ?? 0)))
  let expText = mkSquadExpTooltipText(squad, result)
  if (expText != null)
    textList.append(expText)
  return "\n".join(textList)
}

let mkAwards = @(awards) combineMultispecialistAward(awards).map(@(award) cursors.withTooltip(
  mkBattleHeroAwardIcon(award, [hdpx(50), hdpx(50)]),
  @() loc($"debriefing/award_{award?.id ?? award}")))

let mkShowAnim = @(duration) [{
  prop = AnimProp.opacity, from = 1, to = 1, duration,
  play = true, easing = InOutCubic, trigger
}]

let mkHideAnim = @(duration) [{
  prop = AnimProp.opacity, from = 0, to = 0, duration,
  play = true, easing = InOutCubic, trigger
}]

let mkProgressAnim = @(animDelay) [
  { prop = AnimProp.scale, from = [0, 1], to = [0, 1], play = true,
    duration = animDelay, trigger }
  { prop = AnimProp.scale, from = [0, 1], to = [1, 1], play = true,
    duration = UNLOCK_ADD_EXP_TIME, easing = OutCubic, delay = animDelay, trigger }
]

let function mkProgress(wasLevel, wasExp, addExp, toLevelExp, squad, result, awards, mkAppearAnimations, animDelay) {
  let isNewLevel = wasExp + addExp >= toLevelExp
  let isMaxLevel = toLevelExp == 0
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onHover = @(on) cursors.setTooltip(on ? mkSquadTooltipText(squad, result) : null)
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
         isNewLevel && !isMaxLevel
            ? txt(loc("debriefing/new_level")).__update({
                color = soldierLvlColor
                transform = {}
                animations = mkAppearAnimations(animDelay + UNLOCK_ADD_EXP_TIME, function() {
                  sound_play("ui/debriefing/squad_progression_appear")
                })
              }, body_txt)
            : isMaxLevel
            ? {
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_CENTER
                color = soldierLvlColor
                transform = {}
                text = loc("debriefing/max_level")
                animations = mkAppearAnimations(animDelay + UNLOCK_ADD_EXP_TIME, function() {
                  sound_play("ui/debriefing/squad_progression_appear")
                })
              }.__update(body_txt)
            : txt(loc("levelInfo", { level = wasLevel + 1 })).__update({
                opacity = isNewLevel ? 0 : 1
                animations = isNewLevel ? mkShowAnim(animDelay + UNLOCK_ADD_EXP_TIME - 0.1) : null
              })
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          progressBar({
            value = toLevelExp > 0 ? wasExp.tofloat() / toLevelExp : 0
            addValue = toLevelExp > 0 ? addExp.tofloat() / toLevelExp : 0
            color = Color(150,150,150)
            addValueAnimations = mkProgressAnim(animDelay)
          })
          isNewLevel
            ? {
                rendObj = ROBJ_SOLID
                size = flex()
                margin = [smallPadding, 0]
                color = soldierLvlColor
                animations = mkHideAnim(animDelay + UNLOCK_ADD_EXP_TIME)
              }
            : null
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = gap
        children = mkAwards(awards)
      }
    ]
  }
}

let SQUAD_CARD_PARAMS = {
  squad = null
  awards = []
  animDelay = 0
  armyId = ""
  result = {}
  mkAppearAnimations = @(_delay) null
  onFinishCb = null
}

local function mkSquadProgress(p = SQUAD_CARD_PARAMS) {
  p = SQUAD_CARD_PARAMS.__merge(p)

  let res = { content = null, duration = 0 }
  let squad = p.squad
  if (squad == null)
    return res

  let animDelay = p.animDelay
  let hasNewLevel = squad.wasExp + squad.exp >= squad.toLevelExp
  let premIcon = (squad?.premSquadExpBonus ?? 0) > 0
    ? armiesPresentation?[p.armyId].premIcon
    : squadsPresentation?[p.armyId][squad?.id].premIcon
  return {
    content = {
      size = squadCardSize
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = gap
      behavior = Behaviors.Button
      onHover = @(on) cursors.setTooltip(on ? mkSquadTooltipText(squad, p.result) : null)
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = gap
        children = [
          {
            transform = {}
            animations = p.mkAppearAnimations(animDelay, @() sound_play("ui/debriefing/new_equip"))
            children = [
              mkSquadIcon(squad?.icon, squadIconStyle)
              mkSquadPremIcon(premIcon)
            ]
          }
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = [
              {
                clipChildren = true
                size = [flex(), hdpx(40)]
                children = {
                  delay = [3, 2]
                  speed = hdpx(16)
                  behavior = Behaviors.Marquee
                  orientation = O_VERTICAL
                  size = flex()
                  children = txt(loc(squad.nameLocId)).__update({
                    rendObj = ROBJ_TEXTAREA
                    halign = ALIGN_CENTER
                    behavior = Behaviors.TextArea
                    size = [flex(), SIZE_TO_CONTENT]
                    color = activeTxtColor
                    transform = {}
                    animations = p.mkAppearAnimations(animDelay + 0.1, p.onFinishCb)
                  }, sub_txt)
                }
              }
              mkProgress(squad?.wasLevel ?? 1,
                         squad?.wasExp ?? 0,
                         squad?.exp ?? 0,
                         squad?.toLevelExp ?? 0,
                         squad,
                         p.result,
                         p.awards,
                         p.mkAppearAnimations,
                         animDelay)
            ]
          }
        ]
      }
    }
    duration = TIME_TO_NEXT_SQUAD + (hasNewLevel ? UNLOCK_ADD_EXP_TIME : 0)
  }
}

return mkSquadProgress
