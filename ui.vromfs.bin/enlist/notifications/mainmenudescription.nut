from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { curSectionDetails } = require("%enlist/mainMenu/sectionsState.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let {mkOnlineSaveData} = require("%enlSqGlob/mkOnlineSaveData.nut")

let menuDescShown = mkOnlineSaveData("menuDescShown", @() {})
let TaskTextDesc = Color(150, 150, 160, 220)

let function showDescription(section) {
  let descId = section?.descId
  if ((descId ?? "") == "")
    return

  let id = section.id
  let shown = menuDescShown.watch.value
  if (id in shown)
    return
  menuDescShown.setValue(shown.__merge({ [id] = true }))

  let description = {
    content = {
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          size = [sw(35), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(section.locId)
        }.__update(fontHeading2)
        {
          size = [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_LEFT
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = TaskTextDesc
          text = loc(descId)
          parSpacing = hdpx(20)
        }.__update(fontBody)
      ]
    }
    buttons = [{ text = loc("Ok"), isCurrent = true, isCancel = true }]
  }
  msgbox.showMessageWithContent(description)
}

console_register_command(@() menuDescShown.setValue({}), "ui.resetMenuDescriptions")

curSectionDetails.subscribe(showDescription)