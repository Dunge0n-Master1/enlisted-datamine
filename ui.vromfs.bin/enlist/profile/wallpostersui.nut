from "%enlSqGlob/ui_library.nut" import *

let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { wpCfgFiltered, wpIdSelected } = require("wallpostersState.nut")
let { mkWallposter, makeBigWpImage } = require("wallpostersPkg.nut")
let {
  seenWallposters, markSeenWallposter, markWallpostersOpened
} = require("unseenProfileState.nut")
let { bigPadding, smallPadding, panelBgColor } = require("%enlSqGlob/ui/designConst.nut")


let function mkWallposterBlock(wallposter, unseenList) {
  let { id } = wallposter
  let isUnseen = id in unseenList
  return watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick = function() {
      wpIdSelected(id)
      if (isUnseen)
        markSeenWallposter(id)
    }
    onHover = function(on) {
      if (isUnseen)
        hoverHoldAction("markSeenWallposter", id, @(v) markSeenWallposter(v))(on)
    }
    xmbNode = XmbNode()
    children = mkWallposter(wallposter, sf, isUnseen)
  })
}

let wallpostersListUi = function() {
  let wpFiltered = wpCfgFiltered.value
  let { unseen = {}, unopened = {} } = seenWallposters.value
  return {
    watch = [wpCfgFiltered, seenWallposters]
    rendObj = ROBJ_BOX
    size = flex()
    padding = smallPadding
    onDetach = @() markWallpostersOpened(unopened.keys())
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = makeVertScroll({
          xmbNode = XmbContainer({
            canFocus = false
            scrollSpeed = 5.0
            isViewport = true
          })
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = wpFiltered.map(@(wallposter) mkWallposterBlock(wallposter, unseen))
        }, {
          styling = thinStyle
        })
      }
      @() {
        watch = wpIdSelected
        size = flex()
        children = wpIdSelected.value == null ? null
          : {
              size = flex()
              rendObj = ROBJ_SOLID
              color = panelBgColor
              children = makeBigWpImage(wpFiltered
                .findvalue(@(wp) wp.id == wpIdSelected.value), @() wpIdSelected(null))
            }
      }
    ]
  }
}

return {
  key = "wallposters"
  size = flex()
  children = wallpostersListUi
  onAttach = @() wpIdSelected(null)
  onDetach = @() wpIdSelected(null)
}
