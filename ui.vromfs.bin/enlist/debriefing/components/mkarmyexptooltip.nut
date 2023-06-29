from "%enlSqGlob/ui_library.nut" import *

let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let {
  mkWinXpImage, mkBattleHeroAwardXpImage, mkPremiumAccountXpImage,
  mkBoosterXpImage, mkFreemiumXpImage
} = require("%enlist/debriefing/components/mkXpImage.nut")


let multiplySign = "\u00D7"
let awardPositiveColor = Color(252, 186, 3, 255)
let awardNegativeColor = Color(252, 0, 0, 255)

let mkTooltipHeader = @(text, val) {
  flow = FLOW_HORIZONTAL
  children = [
    txt("{0}{1}".subst(text, loc("ui/colon")))
    txt({text=val, color=awardPositiveColor})
  ]
}

let mkArmyExpTooltip = @(header, exp, squads, expCtor) tooltipBox({
  flow = FLOW_VERTICAL
  children = [
    mkTooltipHeader(header, exp)
    {
      flow = FLOW_VERTICAL
      children = squads.values().filter(@(squad) (squad?.baseExp ?? 0) > 0).map(function(squad) {
        let expDetailed = expCtor(squad)
        return expDetailed != null ? {
          flow = FLOW_HORIZONTAL
          children = [
            txt("{0} - {1} {2}, {3} ".subst(
              loc(squad.nameLocId)
              loc("debriefing/tooltipScore")
              squad?.awardScore ?? 0
              loc("debriefing/tooltipExp")))
            expDetailed
          ]
        } : null
      })
    }
  ]
})

let mkValueWithIcon = @(value, icon) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    txt(value)
    icon
  ]
}


let mkPremSquadXpImage = @(size, override = {}) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [size, size]
      image = Picture($"!ui/skin#premium/prem_squad_debrif_icon.svg:{size}:{size}:K")
    }
  ]
}.__update(override)


let tooltipIconSize = hdpxi(20)

let function getSquadExpDetailed(info) {
  let {
    baseExp = 0,
    resultMult = 1.0,
    anyTeamMult = 1.0,
    lastGameDeserterMult = 1.0,
    awardsMult = 1.0,
    playerCountMult = 1.0,
    boostBonus = 0,
    premAccountBonus = 0,
    premSquadBonus = 0,
    freemMult = 1.0,
    isDeserter = false
  } = info

  let battleResultIcon = !isDeserter
    ? mkWinXpImage(tooltipIconSize)
    : txt({text=loc("debriefing/battleResultDeserterMultShort"), color = awardNegativeColor})
  let anyTeamIcon = txt({text=loc("debriefing/anyTeamMultShort"), color = awardPositiveColor})
  let lastGameDeserterIcon = txt({text=loc("debriefing/lastGameDeserterShort"), color = awardNegativeColor})
  let mkPlayerCountTxt = txt({text=loc("debriefing/playerCountMultArmyExpTooltipShort"), color = awardNegativeColor})
  let battleResultMultIcon = resultMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {resultMult}",
        battleResultIcon)
  let lastGameDeserterMultIcon = lastGameDeserterMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {lastGameDeserterMult}",
        lastGameDeserterIcon)
  let anyTeamMultIcon = anyTeamMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {anyTeamMult}",
        anyTeamIcon)
  let battleHeroMultIcon = awardsMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {awardsMult}",
        mkBattleHeroAwardXpImage(tooltipIconSize))
  let expBoostIcon = boostBonus <= 0 ? null
    : mkValueWithIcon(
        $"+{boostBonus}",
        mkBoosterXpImage(tooltipIconSize))
  let premAccountIcon = premAccountBonus <= 0
    ? null
    : mkValueWithIcon(
        $"+{premAccountBonus}",
        mkPremiumAccountXpImage(tooltipIconSize))
  let premSquadIcon = premSquadBonus <= 0
    ? null
    : mkValueWithIcon(
        $"+{premSquadBonus}",
        mkPremSquadXpImage(tooltipIconSize))
  let playerCountMultIcon = playerCountMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {playerCountMult}",
        mkPlayerCountTxt)
  let freemMultIcon = freemMult == 1.0 ? null
    : mkValueWithIcon(
      $" {multiplySign} {freemMult}",
      mkFreemiumXpImage(tooltipIconSize))

  let needsParentheses = ((resultMult != 1.0) || (awardsMult != 1.0) || (freemMult != 1.0))
    && (boostBonus > 0 || premAccountBonus > 0 || premSquadBonus > 0)

  let resultExp = ((baseExp + boostBonus + premAccountBonus + premSquadBonus) * awardsMult
    * resultMult * lastGameDeserterMult * anyTeamMult * playerCountMult * freemMult).tointeger()
  let showDetailed = baseExp != resultExp
  let resultTxt = txt({text=resultExp, color = awardPositiveColor})
  let baseExpTxt = baseExp != 0 && showDetailed ? txt(baseExp) : null

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = showDetailed
      ? [
          needsParentheses ? txt("(") : null
          baseExpTxt
          expBoostIcon
          premAccountIcon
          premSquadIcon
          needsParentheses ? txt(")") : null
          battleResultMultIcon
          lastGameDeserterMultIcon
          anyTeamMultIcon
          battleHeroMultIcon
          playerCountMultIcon
          freemMultIcon
          txt(" = ")
          resultTxt
        ]
      : [resultTxt]
  }
}

let mkArmyBaseExpTooltip = @(squads, exp) mkArmyExpTooltip(
  loc("debriefing/armyExpBaseTooltipHeader"),
  exp,
  squads,
  @(squad) txt({text = squad?.baseExp ?? 0, color = awardPositiveColor})
)

let resultExpCfg = @(squad, details, isDeserter, armyId)
  squad.__merge({
    boostBonus = ((squad?.baseExp ?? 0) * (details?.armyExpBoost ?? 0)).tointeger()
    premAccountBonus = ((squad?.baseExp ?? 0) * (1.0 + (details?.armyExpBoost ?? 0)) * (squad?.premAccountExpBonus ?? 0)).tointeger(),
    premSquadBonus = ((squad?.baseExp ?? 0) * (1.0 + (details?.armyExpBoost ?? 0)) * (squad?.premSquadExpBonus ?? 0)).tointeger(),
    resultMult = details?.battleResultMult ?? 1.0,
    anyTeamMult = details?.anyTeamMult ?? 1.0,
    lastGameDeserterMult = details?.lastGameDeserterMult ?? 1.0,
    awardsMult = details?.battleHeroAwardsMult ?? 1.0,
    playerCountMult = details?.playerCountMult  ?? 1.0,
    freemMult = details?.freemiumExpMult ?? 1.0,
    isDeserter,
    armyId
  })

let mkArmyResultExpTooltip = @(squads, exp, details, isDeserter, armyId) mkArmyExpTooltip(
  loc("debriefing/armyExpResultTooltipHeader"),
  exp,
  squads,
  @(squad) getSquadExpDetailed(
    resultExpCfg(squad, details, isDeserter, armyId))
)

let premExpCfg = @(squad, details, armyId) {
  premAccountBonus = (squad.baseExp * (1.0 + (details?.armyExpBoost ?? 0)) * (squad?.premAccountExpBonus ?? 0)).tointeger(),
  premSquadBonus = (squad.baseExp * (1.0 + (details?.armyExpBoost ?? 0)) * (squad?.premSquadExpBonus ?? 0)).tointeger(),
  armyId = armyId
}

let function getSquadPremiumExpDetailed(squad, details, armyId) {
  let hasPremiumBonuses = (squad?.premAccountExpBonus ?? 0) + (squad?.premSquadExpBonus ?? 0) > 0
  return hasPremiumBonuses ? getSquadExpDetailed(premExpCfg(squad, details, armyId)) : null
}

let function getPremiumTooltipHeader(hasPremiumAccount, hasPremiumSquad) {
  if (hasPremiumAccount && hasPremiumSquad)
    return loc("debriefing/armyExpPremiumTooltipHeader")
  if (hasPremiumAccount)
    return loc("debriefing/armyExpPremiumAccountTooltipHeader")
  if (hasPremiumSquad)
    return loc("debriefing/armyExpPremiumSquadTooltipHeader")
  return null
}

let mkArmyPremiumExpTooltip = @(squads, exp, details, armyId, hasPremiumAccount, hasPremiumSquad) mkArmyExpTooltip(
  getPremiumTooltipHeader(hasPremiumAccount, hasPremiumSquad)
  exp
  squads
  @(squad) getSquadPremiumExpDetailed(squad, details, armyId)
)

return {
  mkArmyBaseExpTooltip
  mkArmyPremiumExpTooltip
  mkArmyResultExpTooltip
  mkPremSquadXpImage
}