from "%enlSqGlob/ui_library.nut" import *

let colon = loc("ui/colon")
let tabulation = "\u2007" // won't be trimmed
let separator = ""

let commonMultipliersCfg = [
  { stat = "winMult", locId = "debriefing/tooltipWinMult"},
  { stat = "defeatMult", locId = "debriefing/tooltipDefeatMult"},
  { stat = "deserterMult", locId = "debriefing/tooltipDeserterMult"},
  { stat = "premiumSquadMult", locId = "debriefing/tooltipPremiumSquadMult"},
  { stat = "squadRentedMult", locId = "debriefing/squadRentedMult"},
  { stat = "premiumMult", locId = "debriefing/tooltipPremiumMult"},
  { stat = "premiumSquadAndPremiumMult", locId = "debriefing/tooltipPremiumSquadAndPremiumMult"},
  { stat = "battleHeroAwardsMult", locId = "debriefing/tooltipBattleHeroAwardsMult"},
  { stat = "playerCountMult", locId = "debriefing/tooltipPlayerCountMult"},
  { stat = "anyTeamMult", locId = "debriefing/anyTeamMult"},
  { stat = "lastGameDeserterMult", locId = "debriefing/lastGameDeserterMult"},
]

let function getPremMultiplier(stats) {
  let { isRented = false, premSquadExpBonus = 0, premAccountExpBonus = 0 } = stats
  let mult = 1 + premSquadExpBonus + premAccountExpBonus
  let stat = isRented ? "squadRentedMult"
    : premSquadExpBonus > 0 && premAccountExpBonus > 0 ? "premiumSquadAndPremiumMult"
    : premSquadExpBonus > 0 ? "premiumSquadMult"
    : premAccountExpBonus > 0 ? "premiumMult"
    : ""
  return stat == "" ? {} : { [stat] = mult }
}

let function getBattleResultMultiplier(stats, result) {
  let mult = stats?.battleResultMult ?? 0
  return (result?.deserter ?? false) ? {deserterMult = mult} :
         (result?.success ?? false) ? {winMult = mult} :
         (result?.fail ?? false) ? {defeatMult = mult} :
         {}
}

let squadMultipliersCfg = [].extend(commonMultipliersCfg, [
  { stat = "expBonus", locId = "debriefing/squadBonusExp", convertVal = @(v) 1 + v },
  { stat = "squadExpBoost", locId = "debriefing/squadExpBoost", convertVal = @(v) 1 + v },
]).map(@(s) { toString = @(v) v.tostring() }.__update(s))

let soldierMultipliersCfg = [].extend(commonMultipliersCfg, [
  { stat = "classBonus", locId = "debriefing/classBonusExp", convertVal = @(v) 1 + v },
  { stat = "soldierExpBoost", locId = "debriefing/soldierExpBoost", convertVal = @(v) 1 + v },
]).map(@(s) { toString = @(v) v.tostring() }.__update(s))

let function mkTooltipMultipliersText(stats, cfg) {
  let textList = cfg.map(@(s) s.__merge({value = stats?[s.stat]}))
    .filter(@(s) s.value != null)
    .map(@(s) s.__update({value = s?.convertVal(s.value) ?? s.value}))
    .filter(@(s) s.value != 1.0)
    .map(@(s) "".concat(tabulation, loc(s.locId), colon, s.toString(s.value)))
  return "\n".join(textList)
}

let tooltipField = @(locId, value) "".concat(loc(locId), colon, value)

let function mkExperienceTooltipText(stats, cfg) {
  local expText = stats?.toLevelExp == 0
    ? loc("squad/squadMaxLvl")
    : tooltipField("debriefing/expAdded", stats?.exp ?? 0)
  let multipliers = mkTooltipMultipliersText(stats, cfg)
  if (multipliers != "") expText = "\n".join([
    tooltipField("debriefing/tooltipBaseExp", stats?.baseExp ?? 0)
    "".concat(loc("debriefing/tooltipExpMultipliers"), colon)
    multipliers
    separator
    expText
  ])
  return expText
}

let mkSquadExpTooltipText = @(stats, result) mkExperienceTooltipText(
  stats.__merge(getPremMultiplier(stats), getBattleResultMultiplier(stats, result)),
  squadMultipliersCfg)

let mkSoldierExpTooltipText = @(stats, result) mkExperienceTooltipText(
  stats.__merge(getPremMultiplier(stats), getBattleResultMultiplier(stats, result)),
  soldierMultipliersCfg)

return {
  mkSquadExpTooltipText
  mkSoldierExpTooltipText
}
