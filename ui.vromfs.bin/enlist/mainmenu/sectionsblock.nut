from "%enlSqGlob/ui_library.nut" import *

let { sectionsSorted, curSection, setCurSection } = require("sectionsState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let profileInfoBlock = require("profileInfoBlock.nut")
let { columnGap, midPadding, colPart } = require("%enlSqGlob/ui/designConst.nut")
let { mkTab, backgroundMarker } = require("%enlist/components/mkTab.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let campaignTitle = require("%enlist/campaigns/campaignTitleUi.nut")

let navHeight = colPart(1.19)

let isFirstSection = Computed(@() curSection.value == sectionsSorted?[0].id)

let function trySwitchSection(sectionId) {
  let onExitCb = sectionsSorted
    .findvalue(@(s) s?.id == curSection.value)?.onExitCb ?? @() true
  if (onExitCb())
    setCurSection(sectionId)
}


let goToFirstSection = {
  key ="back"
  hotkeys = [["^{0} | Esc".subst(JB.B), {
    action = @() trySwitchSection(sectionsSorted?[0].id)
    description = loc("BackBtn")
  }]]
}

let sectionsHotkeys = @() {
  watch = isFirstSection
  children = isFirstSection.value ? null : goToFirstSection
}

let function changeTab(delta, isLooped = false) {
  let filtered = sectionsSorted.filter(@(val) val?.selectable ?? true)
  let next_idx = (filtered.findindex(@(val) val.id == curSection.value) ?? 0) + delta
  let total = filtered.len()
  let tabId = filtered[ isLooped
    ? ((next_idx + total) % total)
    : clamp(next_idx, 0, total - 1)
  ].id
  trySwitchSection(tabId)
}


let gamepadNav = @(key, action) @() {
  size = [SIZE_TO_CONTENT, premiumBtnSize]
  valign = ALIGN_CENTER
  children = mkHotkey(key, action)
}

let changeTabWrap = @(delta) changeTab(delta, true)

let maintabs = {
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_BOTTOM
  halign = ALIGN_LEFT
  hplace = ALIGN_LEFT
  children = [
    backgroundMarker
    @() {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      gap = midPadding
      halign = ALIGN_LEFT
      valign = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      children = sectionsSorted.map(function(s){
        let action = s?.onClickCb ?? @() trySwitchSection(s.id)
        let params = s.__merge({ action })
        return mkTab(params, curSection)
      })
    }
  ]
}

let sectionsUi = {
  size = flex()
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = [
    maintabs
    gamepadNav("^J:LB | Q", @() changeTab(-1))
    gamepadNav("^J:RB | E", @() changeTab(1))
    {
      hotkeys = [
        ["^Tab", @() changeTabWrap(1)],
        ["^L.Shift Tab | R.Shift Tab", @() changeTabWrap(-1)]
      ]
    }
  ]
}


let navHeader = {
  size = flex()
  children = [
    {
      size = [flex(), navHeight]
      flow = FLOW_HORIZONTAL
      children = [
        sectionsUi
        profileInfoBlock
        sectionsHotkeys
      ]
    }
    campaignTitle()
  ]
}

return navHeader