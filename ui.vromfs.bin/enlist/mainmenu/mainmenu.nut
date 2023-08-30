from "%enlSqGlob/ui_library.nut" import *

let { sectionsSorted, sectionsGeneration, curSection } = require("sectionsState.nut")
let bottomBar = require("%enlist/mainMenu/bottomRightButtons.nut")
let navHeader = require("sectionsBlock.nut")
let { mkMenuScene, menuContentAnimation } = require("mkMenuScene.nut")


let sectionContent = function() {
  let section = (sectionsSorted ?? []).findvalue(@(val) val?.id == curSection.value)
  let children = section?.getContent()
  let sectionWatched = section?.sectionWatched
  return {
    watch = [curSection, sectionsGeneration] //animations does not restart when parent not changed
    size = flex()
    children = @() {
      size = flex()
      children
      watch = [sectionWatched, curSection]
      key = curSection.value
      transform = {}
      animations = menuContentAnimation
    }
  }
}

return mkMenuScene(navHeader, sectionContent, bottomBar)
