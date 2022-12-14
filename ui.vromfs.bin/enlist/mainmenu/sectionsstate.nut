from "%enlSqGlob/ui_library.nut" import *

let { doesSceneExist, scenesListGeneration } = require("%enlist/navState.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")


let mainSectionId = isNewDesign.value ? "MAINMENU" : "SOLDIERS"

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
  sectionsGeneration(sectionsGeneration.value+1)
  if (sectionsSorted?.len() && !(sectionsSorted ?? []).findvalue(@(s) s?.id == curSection.value))
    curSection(sectionsSorted?[0].id)
}

let function setCurSection(id) {
  let section = sectionsSorted.findvalue(@(s) s?.id == id)
  if (section == null)
    return
  curSection(id)
}


let function jumpToArmyProgress() {
  if (isNewDesign.value)
    isArmyProgressOpened(true)
  else
    setCurSection("SQUADS")
}

let function jumpToResearches() {
  if (isNewDesign.value)
    isResearchesOpened(true)
  else
    setCurSection("RESEARCHES")
}


let hasArmyProgressOpened = Computed(@() isNewDesign.value
  ? isArmyProgressOpened.value
  : curSection.value == "SQUADS"
)

let hasResearchesOpened = Computed(@() isNewDesign.value
  ? isResearchesOpened.value
  : curSection.value == "RESEARCHES"
)

let hasMainSectionOpened = Computed(@() curSection.value == mainSectionId)

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
}
