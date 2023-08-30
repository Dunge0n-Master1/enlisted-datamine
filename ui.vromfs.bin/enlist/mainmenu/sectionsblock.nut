from "%enlSqGlob/ui_library.nut" import *

let { sectionsSorted, curSection, trySwitchSection, tryBackSection, sectionsGeneration
} = require("sectionsState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")
let profileInfoBlock = require("profileInfoBlock.nut")
let { largePadding, midPadding, navHeight } = require("%enlSqGlob/ui/designConst.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { mkTab, backgroundMarker } = require("%enlist/components/mkTab.nut")
let campaignTitle = require("%enlist/campaigns/campaignTitleUi.nut")


let isFirstSection = Computed(@() curSection.value == sectionsSorted?[0].id)

let goToFirstSection = {
  key ="back"
  hotkeys = [[$"^{JB.B} | Esc", {
    action = @() tryBackSection(sectionsSorted?[0].id)
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

let changeTabWrap = @(delta) changeTab(delta, true)

let maintabs = {
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_BOTTOM
  halign = ALIGN_LEFT
  hplace = ALIGN_LEFT
  children = [
    @() {
      watch = sectionsGeneration
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      gap = midPadding
      halign = ALIGN_LEFT
      valign = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      children = sectionsSorted.map(function(section){
        let action = section?.onClickCb ?? @() trySwitchSection(section.id)
        return mkTab(section, action, curSection)
      })
    }
    backgroundMarker
  ]
}

let jbwrap = @(children) { children, padding = [hdpx(10),0,0,0]}
let lb = jbwrap(mkHotkey("^J:LB", @() changeTab(-1)))
let rb = jbwrap(mkHotkey("^J:RB", @() changeTab(1)))

let sectionsUi = @() {
  size = flex()
  watch = isGamepad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = largePadding
  children = [
    isGamepad.value ? lb : null
    maintabs
    isGamepad.value ? rb : null
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
    campaignTitle
  ]
}

return navHeader