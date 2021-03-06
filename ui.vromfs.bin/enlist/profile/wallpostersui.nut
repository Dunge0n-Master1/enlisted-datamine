from "%enlSqGlob/ui_library.nut" import *

let { borderColor } = require("profilePkg.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { wpCfgFiltered, wpIdSelected } = require("wallpostersState.nut")
let { mkWallposter, makeBigWpImage } = require("wallpostersPkg.nut")
let { unseenWallposters, markSeenWallposter } = require("unseenProfileState.nut")


let function mkWallposterBlock(wallposter, unseenList) {
  let { id } = wallposter
  let isUnseen = unseenList.findindex(@(wp) wp.tpl == id) != null
  return watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick = function() {
      wpIdSelected(id)
      markSeenWallposter(id)
    }
    xmbNode = XmbNode()
    children = mkWallposter(wallposter, sf, isUnseen)
  })
}

let wallpostersListUi = function() {
  let wpFiltered = wpCfgFiltered.value
  let selectedId = wpIdSelected.value
  let unseenList = unseenWallposters.value
  return {
    watch = [wpCfgFiltered, wpIdSelected, unseenWallposters]
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = flex()
    flow = FLOW_VERTICAL
    gap = bigPadding
    padding = smallPadding
    borderColor = borderColor(0)
    children = selectedId == null
      ? makeVertScroll({
          xmbNode = XmbContainer({
            canFocus = @() false
            scrollSpeed = 5.0
            isViewport = true
          })
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = wpFiltered.map(@(wallposter) mkWallposterBlock(wallposter, unseenList))
        }, {
          styling = thinStyle
        })
      : makeBigWpImage(wpFiltered.findvalue(@(wp) wp.id == selectedId), @() wpIdSelected(null))
  }
}

return {
  key = "wallposters"
  size = flex()
  children = wallpostersListUi
  onAttach = @() wpIdSelected(null)
  onDetach = @() wpIdSelected(null)
}
