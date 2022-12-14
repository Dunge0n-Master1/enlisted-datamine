from "%enlSqGlob/ui_library.nut" import *

let { sectionsSorted, sectionsGeneration, curSection } = require("sectionsState.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let bottomBar = isNewDesign.value
  ? require("%enlist/mainScene/bottomBar.nut")
  : require("%enlist/mainMenu/bottomRightButtons.nut")
let navHeader = isNewDesign.value
  ? require("sectionsBlock.nut")
  : require("%enlist/mainMenu/sections.nut")
let { mkMenuScene, menuContentAnimation } = require("mkMenuScene.nut")


let sectionContent = @() {
  watch = [curSection, sectionsGeneration] //animations does not restart when parent not changed
  size = flex()
  children = {
    size = flex()
    children = (sectionsSorted ?? []).findvalue(@(val) val?.id == curSection.value)?.content
    key = curSection.value
    transform = {}
    animations = menuContentAnimation
  }
}

return mkMenuScene(navHeader, sectionContent, bottomBar)
