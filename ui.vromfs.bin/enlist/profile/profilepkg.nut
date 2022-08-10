from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let {
  defTxtColor, selectedTxtColor, defInsideBgColor, activeBgColor,
  blurBgFillColor, titleTxtColor, disabledTxtColor,
  bigPadding, smallPadding, smallOffset, activeTxtColor, rowBg
} = require("%enlSqGlob/ui/viewConst.nut")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { armies } = require("%enlist/soldiers/model/state.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { playerStatsList, killsList } = require("profileState.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")


let PROFILE_WIDTH = fsh(100)

let DEFAULT_FOOTER_PARAMS = {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_HORIZONTAL
}

const MAIN_GAME_STAT = "main_game"

let headerHeight = hdpxi(50)
let armyIconSize = hdpxi(28)

let selectedCampaign = Watched(null)

let txtColor = @(sf, isSelected = false) isSelected ? selectedTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor

let bgColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? defInsideBgColor
  : blurBgFillColor

let borderColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? activeBgColor
  : disabledTxtColor

let mkFooterWithButtons = @(buttonsList, params = DEFAULT_FOOTER_PARAMS) {
  children = buttonsList
}.__merge(params)

let mkFooterWithBackButton = @(onClick, params = DEFAULT_FOOTER_PARAMS)
  mkFooterWithButtons([
    Bordered(loc("BackBtn"), onClick, {
      margin = 0
      hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
    })
  ], params)

let mkText = @(text, customStyle = {}) {
  rendObj = ROBJ_TEXT
  color = activeTxtColor
  text
}.__update(sub_txt, customStyle)

let campaignSlotStyle = {
  rendObj = ROBJ_SOLID
  size = [flex(), hdpx(50)]
  behavior = Behaviors.Button
}

let statValueStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
}

let statNameStyle = {
  size = [pw(60), SIZE_TO_CONTENT]
}

let mkCampaignInfoBtn = @(campaign, isSelected)
  watchElemState(@(sf) {
    onClick = isSelected ? null : @() selectedCampaign(campaign.id)
    padding = [0, smallOffset]
    valign = ALIGN_CENTER
    color = bgColor(sf, isSelected)
    children = mkText(loc(campaign.title), body_txt.__merge({
      color = txtColor(sf, isSelected)
    }))
  }.__update(campaignSlotStyle))

let mkAllCampaignBtn = @(selCampaignWatch)
  watchElemState(function(sf) {
    let isSelected = selCampaignWatch.value == null
    return {
      onClick = @() selCampaignWatch(null)
      padding = [0, smallOffset]
      valign = ALIGN_CENTER
      color = bgColor(sf, isSelected)
      children = mkText(loc("menu/campaigns"), body_txt.__merge({
        color = txtColor(sf, isSelected)
      }))
    }.__update(campaignSlotStyle)
  })

let mkCampaignsListUi = @(campListWatch) function() {
  let campList = campListWatch.value
  let campCfg = gameProfile.value?.campaigns

  return {
    watch = [campListWatch, armies, gameProfile, selectedCampaign]
    size = [pw(35), flex()]
    flow = FLOW_VERTICAL
    gap = bigPadding
    padding = [headerHeight,0,0,0]
    children = [mkAllCampaignBtn(selectedCampaign)]
      .extend(campList.map(function(campaignId) {
        let campaignCfg = campCfg?[campaignId]
        if (campaignCfg == null)
          return null

        let isSelected = selectedCampaign.value == campaignCfg.id
        return mkCampaignInfoBtn(campaignCfg, isSelected)
      }))
  }
}

let mkStats = @(baseStats) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = baseStats.map(@(s, idx) {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    padding = [smallPadding, smallOffset]
    color = rowBg(0, idx)
    children = [
      mkText(loc($"debriefing/awards/{s.statId}"), statNameStyle)
    ].extend(s.statVal.map(@(v) mkText(v, statValueStyle)))
  })
}

let mkStatsHeader = @(armiesList, showLevel) @() {
  watch = armies
  size = [flex(), headerHeight]
  flow = FLOW_HORIZONTAL
  padding = [0, smallOffset]
  valign = ALIGN_CENTER
  children = [ mkText(loc("debriefing/tab/statistic"), body_txt.__merge(statNameStyle)) ]
    .extend(armiesList
      .filter(@(armyId) armyId != MAIN_GAME_STAT)
      .map(@(armyId) {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        padding = smallPadding
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        children = [
          !showLevel ? null
            : mkText(loc("level/short", { level = armies.value?[armyId].level ?? 0 }))
          mkArmyIcon(armyId, armyIconSize, { margin = 0 })
        ]
      }))
}

let function mkPlayerStatistics(statsWatch, showLevel = true) {
  let playerCardStats = Computed(function() {
    let campaignsCfg = gameProfile.value?.campaigns
    let selCampaign = selectedCampaign.value
    let selCampaignCfg = campaignsCfg?[selCampaign]

    let armiesList = (selCampaignCfg?.armies ?? []).map(@(a) a.id).sort()
    if (armiesList.len() == 0)
      armiesList.append(MAIN_GAME_STAT)

    let globalStats = statsWatch.value?.stats["global"] ?? {}
    let stats = armiesList.map(@(armyId) globalStats?[armyId] ?? {})
    let res = {
      campaignTitle = selCampaignCfg?.title
      armiesList
      baseStats = playerStatsList.map(@(statData) {
        statId = statData.statId
        statVal = stats.map(@(stat)
          statData.calculator(stat) + (statData?.unitSign ?? "")
        )
      })
      killsData = killsList.map(@(statId) {
        statId
        statVal = stats.map(@(stat) stat?[statId] ?? 0)
      })
    }

    return res
  })

  return function() {
    let { baseStats, killsData, armiesList } = playerCardStats.value
    return {
      watch = playerCardStats
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        mkStatsHeader(armiesList, showLevel)
        mkStats(baseStats)
        { size = [0, smallOffset] }
        mkStats(killsData)
      ]
    }
  }
}

return {
  mkFooterWithBackButton
  mkFooterWithButtons
  txtColor
  bgColor
  borderColor
  mkPlayerStatistics
  mkCampaignsListUi

  PROFILE_WIDTH
}
