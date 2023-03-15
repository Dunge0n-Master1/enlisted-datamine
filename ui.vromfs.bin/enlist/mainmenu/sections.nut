from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { TextActive, Active, TextHighlight, TextDefault } = require("%ui/style/colors.nut")
let { navHeight } = require("mainmenu.style.nut")
let { horGap } = require("%enlist/components/commonComps.nut")
let { sectionsSorted, curSection, setCurSection, sectionsGeneration } = require("sectionsState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let menuHeaderRightUiList = require("menuHeaderRightUiList.nut")
let { soundActive } = require("%ui/components/textButton.nut")


let unseenIcon = blinkUnseenIcon(0.8)
if (sectionsSorted?.len() && !(sectionsSorted ?? []).findvalue(@(s) s?.id == curSection.value))
  setCurSection(sectionsSorted?[0].id)

let getActiveSections = @() (sectionsSorted ?? []).filter(@(s) !s?.watch || s?.watch.value)

let function trySwitchSection(setSectionCb) {
  let onExitCb = (sectionsSorted ?? [])
    .findvalue(@(s) s?.id == curSection.value)?.onExitCb ?? @() true
  if (onExitCb())
    setSectionCb()
}

let function defCtor(section, stateFlags, group, isCurrent) {
  let { id, locId, unseenWatch = null, addChild = null } = section
  local unseenChild
  if (unseenWatch)
    unseenChild = @() {
      watch = unseenWatch
      key = $"section_unseen_{id}"
      hplace = ALIGN_RIGHT
      pos = [hdpx(15), -hdpx(10)]
      children = unseenWatch.value ? unseenIcon : null
    }

  return function(){
    local color
    local fontFx = FFT_NONE
    if (isCurrent.value) {
      color = Active
      fontFx = FFT_GLOW
    } else {
      let sf = stateFlags.value
      color = (sf & S_ACTIVE) ? TextActive
              : (sf & S_HOVER) ? TextHighlight
              : TextDefault
    }
    let children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(locId)
        color
        fontFx
        fontFxColor = TextDefault
        fontFxFactor = min(hdpx(48), 48)
        hplace = ALIGN_CENTER
        group
      }.__update(h2_txt)
      unseenChild
      addChild
    ]
    return {
      key = $"section_{id}"
      children
      group
    }
  }
}

let function sectionLink(section) {
  let stateFlags = Watched(0)
  let isCurrent = Computed(@() section.id==curSection.value)
  let group = ElemGroup()
  let ctor = section?.ctor ?? defCtor
  return function() {
    let children = ctor(section, stateFlags, group, isCurrent)

    return {
      watch = [stateFlags, isCurrent]
      key = section.id
      padding = [fsh(1), 0]
      behavior = Behaviors.Button
      skipDirPadNav = true
      sound = soundActive
      onClick = @() section?.onClickCb != null ? section.onClickCb() : trySwitchSection(@() setCurSection(section.id))
      onElemState = @(sf) stateFlags(sf)
      group = group
      valign = ALIGN_CENTER
      children = children
      size = SIZE_TO_CONTENT
    }
  }
}

let sectionsHotkeys = @() {
  watch = [curSection, sectionsGeneration]
  children = curSection.value != getActiveSections()?[0].id
    ? {
        key ="back"
        hotkeys = [[$"^{JB.B} | Esc", {
          action = @() trySwitchSection(@() setCurSection(getActiveSections()?[0].id))
          description = loc("BackBtn")
        }]]
      }
    : null
}

let function changeTab(delta, cycle=false) {
  let filtered = getActiveSections().filter(@(val) val?.selectable ?? true)
  let next_idx = (filtered.findindex(@(val) val.id == curSection.value) ?? -1) + delta
  let total = filtered.len()
  let tabId = filtered[cycle
    ? ((next_idx + total) % total)
    : clamp(next_idx, 0, total - 1)].id
  trySwitchSection(@() setCurSection(tabId))
}

let function sectionsUi() {
  let changeTabWrap = @(delta) changeTab(delta, true)
  let maintabs = @() {
    gap = horGap
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = getActiveSections().map(@(s) sectionLink(s))
    watch = sectionsSorted?.map(@(s) s?.watch).filter(@(w) w != null).append(sectionsGeneration)
  }
  let tb = @(key, action) @() {
    children = mkHotkey(key, action)
    isHidden = !isGamepad.value
    watch = isGamepad
    size = SIZE_TO_CONTENT
  }
  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = fsh(1)
    children = [
      {hotkeys=[["^Tab", @() changeTabWrap(1)], ["^L.Shift Tab | R.Shift Tab", @() changeTabWrap(-1)]]}
      tb("^J:LB", @() changeTab(-1))
      maintabs
      tb("^J:RB", @() changeTab(1))
    ]
  }
}

let menuRightUiComp = {
  size = [SIZE_TO_CONTENT, navHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = menuHeaderRightUiList
}

let navHeader = @() {
  size = flex()
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    sectionsUi
    {size=[flex(),0]}
    menuRightUiComp
  ].append(sectionsHotkeys)
}

return navHeader