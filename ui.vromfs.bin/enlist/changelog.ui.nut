from "%enlSqGlob/ui_library.nut" import *

/*
  TODO:
    ? make some header (version number)
*/

let scrollbar = require("%ui/components/scrollbar.nut")
let {formatText} = require("%enlist/components/formatText.nut")
let { curPatchnote, chosenPatchnoteContent, selectPatchnote,
  chosenPatchnoteTitle, chosenPatchnoteLoaded, versions, patchnotesReceived, extNewsUrl
} = require("changeLogState.nut")
let spinner = require("%ui/components/spinner.nut")
let { smallPadding, titleTxtColor, defTxtColor, transpBgColor, weakTxtColor,
  accentColor, hoverSlotBgColor, darkTxtColor, fullTransparentBgColor, selectedPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let waitingSpinner = spinner()

let scrollHandler = ScrollHandler()

let function onTabClicked(v) {
  if (curPatchnote.value != v) {
    selectPatchnote(v)
    scrollHandler.scrollToY(0)
  }
}

let function mkVersionTab(v) {
  let isCurrent = Computed(@() curPatchnote.value == v)
  let group = ElemGroup()
  return watchElemState(@(sf) {
    watch = isCurrent
    rendObj = ROBJ_BOX
    size = flex()
    valign = ALIGN_CENTER
    group
    behavior = Behaviors.Button
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isCurrent.value ? selectedPanelBgColor
      : fullTransparentBgColor
    borderWidth = isCurrent.value ? [0, 0, hdpx(4), 0] : 0
    borderColor = accentColor
    onClick = @() onTabClicked(v)
    skipDirPadNav = false // TODO disable in future to support consistent behavior with top menu
    maxWidth = hdpx(200)
    children = {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      maxWidth = hdpx(200)
      group
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = sf & S_HOVER ? darkTxtColor
        : isCurrent.value ? titleTxtColor
        : defTxtColor
      text = v?.titleshort ?? v.tVersion
    }
  })
}

let missedPatchnoteText = formatText([loc("NoUpdateInfo", "Oops... No information yet :(")])
let isVersionsExists = Computed(@() versions.value.len() > 0)

let patchnoteSelector = @() {
  watch = [versions, patchnotesReceived, isVersionsExists, isGamepad]
  size = [flex(), fsh(6)]
  flow = FLOW_HORIZONTAL
  halign = isGamepad.value ? ALIGN_CENTER : ALIGN_LEFT
  onAttach = function(){
    if (patchnotesReceived.value && curPatchnote.value!=null)
      selectPatchnote(curPatchnote.value)
  }
  children = patchnotesReceived.value && isVersionsExists.value
    ? (clone versions.value).reverse().map(mkVersionTab)
    : missedPatchnoteText
}

let seeMoreUrl = {
  t="url"
  platform="pc,ps4"
  url=extNewsUrl
  v=loc("visitGameSite", "See game website for more details")
  margin = [hdpx(50), 0, 0, 0]
}

let patchnoteLoading = freeze({
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(20)
  valign = ALIGN_CENTER size = [flex(), fsh(20)]
  padding = fsh(2)
  children = [
    formatText([{v = loc("Loading"), t = "h2", halign = ALIGN_CENTER}])
    waitingSpinner
  ]
})

let function currentPatchnote(){
  local text = (chosenPatchnoteContent.value ?? "")!="" ? chosenPatchnoteContent.value : missedPatchnoteText
  if (type(text)!="array")
    text = [text, seeMoreUrl]
  else
    text = (clone text).append(seeMoreUrl)
  if (chosenPatchnoteTitle.value != "")
    text = [{v = chosenPatchnoteTitle.value, t="h1"}].extend(text)
  return {
    rendObj = ROBJ_SOLID
    color = transpBgColor
    watch = [chosenPatchnoteLoaded, chosenPatchnoteContent, chosenPatchnoteTitle, curPatchnote]
    children = scrollbar.makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      padding = smallPadding
      children = chosenPatchnoteLoaded.value
        ? [{
            rendObj = ROBJ_TEXT
            text = curPatchnote.value?.date.split("T")[0]
            hplace = ALIGN_RIGHT
            color = weakTxtColor
          }].append(formatText(text))
        : patchnoteLoading
    }, { scrollHandler })
    size = [sw(55), sh(75)]
  }
}

return {
  currentPatchnote
  patchnoteSelector
}