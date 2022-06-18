from "%enlSqGlob/ui_library.nut" import *

let {doesSceneExist, scenesListGeneration} = require("%enlist/navState.nut")

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

return {
  curSection = Computed(@() curSection.value)
  curSectionDetails
  sectionsSorted
  sectionsGeneration
  setSectionsSorted
  setCurSection
  isMainMenuVisible
}
