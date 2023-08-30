from "%enlSqGlob/ui_library.nut" import *

let { doesSceneExist, scenesListGeneration } = require("%enlist/navState.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")

let mainSectionId = "SOLDIERS"

let isArmyProgressOpened = mkWatched(persist, "isArmyProgressOpened", false)
let isResearchesOpened = mkWatched(persist, "isResearchesOpened", false)

let curSection = mkWatched(persist, "curSection")
let sectionsGeneration = mkWatched(persist, "sectionsGeneration", 0)
let isMainMenuVisible = Watched(false)
let sectionsSorted = []

let curSectionDetails = Computed(function() {
  let section = doesSceneExist(scenesListGeneration.value, sectionsGeneration.value) || sectionsSorted.len()==0
    ? null
    : sectionsSorted.findvalue(@(s) s?.id == curSection.value)
  if (section==null)
    return null
  return {camera=section.camera }
})

let function setSectionsSorted(sections){
  let found = {}
  foreach (k, v in sections) {
    if (v?.id==null)
      v.id<-k
    if (v.id in found){
      assert(false, "id of sections should be unique")
      v.id<-k
    }
    found[v.id] <- null
  }
  sectionsSorted.clear()
  sectionsSorted.extend(sections)
  if (!sectionsSorted.findvalue(@(s) s?.id == curSection.value))
    curSection(sectionsSorted?[0].id)
  sectionsGeneration(sectionsGeneration.value + 1)
}

let function setCurSection(id) {
  let section = sectionsSorted.findvalue(@(s) s?.id == id)
  if (section == null)
    return
  curSection(id)
}

const CAMPAIGN_PROGRESS = "CAMPAIGN"
let function jumpToArmyProgress() {
  setCurSection(CAMPAIGN_PROGRESS)
}

let function jumpToResearches() {
  setCurSection("RESEARCHES")
}


let hasArmyProgressOpened = Computed(@() curSection.value == CAMPAIGN_PROGRESS)

let hasResearchesOpened = Computed(@() curSection.value == "RESEARCHES")

let hasMainSectionOpened = Computed(@() curSection.value == mainSectionId)

let function trySwitchSection(sectionId) {
  let { onExitCb = @() true } = sectionsSorted.findvalue(@(s) s?.id == curSection.value)
  if (onExitCb()) {
    setCurSection(sectionId)
    sound_play("ui/enlist/button_click")
  }
}

let function tryBackSection(sectionId) {
  let { onBackCb = @() true } = sectionsSorted.findvalue(@(s) s?.id == curSection.value)
  if (onBackCb())
    trySwitchSection(sectionId)
}

return {
  curSection = Computed(@() curSection.value)
  curSectionDetails
  sectionsSorted
  sectionsGeneration
  setSectionsSorted
  setCurSection
  isMainMenuVisible
  mainSectionId

  isArmyProgressOpened
  isResearchesOpened

  jumpToArmyProgress
  jumpToResearches

  hasMainSectionOpened
  hasArmyProgressOpened
  hasResearchesOpened
  trySwitchSection
  tryBackSection
}
