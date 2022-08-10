from "%enlSqGlob/ui_library.nut" import *

/*
  TODO:
    ? make some header (version number)
*/

let scrollbar = require("%ui/components/scrollbar.nut")
let {formatText} = require("%enlist/components/formatText.nut")
let { curPatchnote, requestPatchnote, chosenPatchnote, haveUnseenVersions, chosenPatchnoteContent,
chosenPatchnoteTitle, chosenPatchnoteLoaded, versions, patchnotesReceived, extNewsUrl
} = require("changeLogState.nut")
let spinner = require("%ui/components/spinner.nut")

let gap = hdpx(10)

let scrollHandler = ScrollHandler()

let function selectPatchnote(v) {
  chosenPatchnote(v)
  requestPatchnote(v)
  scrollHandler.scrollToY(0) // necessary because of the obscure behavior of the vertical scroll position
}

let function patchnote(v) {
  let stateFlags = Watched(0)
  return @() {
    size = flex()
    maxWidth = hdpx(150)
    behavior = [Behaviors.Button, Behaviors.TextArea]
    onClick = @() selectPatchnote(v)
    watch = [stateFlags, curPatchnote]
    onElemState = @(sf) stateFlags(sf)
    skipDirPadNav = false
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = stateFlags.value & S_HOVER
    ? Color(200,200,200)
    : curPatchnote.value == v
      ? Color(100,100,200)
      : Color(80,80,80)
    text = v?.titleshort ?? v.tVersion
  }
}

let missedPatchnoteText = formatText([loc("NoUpdateInfo", "Oops... No information yet :(")])
let isVersionsExists = Computed(@() versions.value.len() > 0)
let notesgap = freeze({
  rendObj = ROBJ_SOLID
  color = Color(80,80,80)
  size = [hdpx(1), flex()]
  margin = [0, gap]
})

let patchnoteSelector = @() {
  size = [flex(), fsh(6)]
  flow = FLOW_HORIZONTAL
  gap = notesgap
  onAttach = function(){
    if (patchnotesReceived.value && curPatchnote.value!=null)
      selectPatchnote(curPatchnote.value)
  }
  children = patchnotesReceived.value && isVersionsExists.value ? versions.value.map(patchnote) : missedPatchnoteText
  watch = [versions, curPatchnote, patchnotesReceived, isVersionsExists]
}

patchnotesReceived.subscribe(function(v){
  if (!v || !haveUnseenVersions.value || curPatchnote.value==null)
    return
  selectPatchnote(curPatchnote.value)
})

let seeMoreUrl = {
  t="url"
  platform="pc,ps4"
  url=extNewsUrl
  v=loc("visitGameSite", "See game website for more details")
  margin = [hdpx(50), 0, 0, 0]
}

let patchnoteLoading = freeze({
  children = [formatText([{v = loc("Loading"), t = "h2", halign = ALIGN_CENTER}]), spinner]
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(20)
  valign = ALIGN_CENTER size = [flex(), fsh(20)]
  padding = fsh(2)
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
    color = Color(10,10,10,10)
    watch = [chosenPatchnoteLoaded, chosenPatchnoteContent, chosenPatchnoteTitle, curPatchnote]
    children = scrollbar.makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      padding = gap
      children = chosenPatchnoteLoaded.value
        ? [{
            rendObj = ROBJ_TEXT
            text = curPatchnote.value?.date.split("T")[0]
            hplace = ALIGN_RIGHT
            color = Color(100,100,100)
          }].append(formatText(text))
        : patchnoteLoading
    }, { scrollHandler })
    size = [sw(80), sh(75)]
  }
}

return {
  currentPatchnote
  patchnoteSelector
}