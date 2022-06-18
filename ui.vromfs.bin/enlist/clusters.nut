from "%enlSqGlob/ui_library.nut" import *

let {ControlBgOpaque, BtnBgDisabled, BtnBdDisabled, BtnTextVisualDisabled} = require("%ui/style/colors.nut")
let {canChangeQueueParams, queueClusters, isInQueue} = require("%enlist/state/queueState.nut")
let {availableClusters, clusters, clusterLoc} = require("clusterState.nut")
let popupsState = require("%enlist/popup/popupsState.nut")
let textButton = require("%ui/components/textButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let multiselect = require("%enlist/components/multiselect.nut")

let borderColor = Color(60,60,60,255)
let btnParams = {
  size = [flex(), hdpx(50)],
  halign = ALIGN_LEFT,
  margin = 0,
  textMargin = [0, 0, 0, fsh(1.5)],
  clipChildren = true
  textParams = { behavior = Behaviors.Marquee}
}
let visualDisabledBtnParams = btnParams.__merge({
  style = {
    BgNormal = BtnBgDisabled
    BdNormal = BtnBdDisabled
    TextNormal = BtnTextVisualDisabled
  }
})

let clusterSelector = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = availableClusters
  children = multiselect({
    selected = clusters
    minOptions = 1
    options = availableClusters.value.map(@(c) { key = c, text = clusterLoc(c) })
  })
}

let function showCantChangeMessage() {
  let text = isInQueue.value ? loc("Can't change params while in queue") : loc("Only squad leader can change params")
  popupsState.addPopup({ id = "groupSizePopup", text = text, styleName = "error" })
}

let mkClustersUi = kwarg(function(style = {}){
  let size = style?.size ?? [hdpx(250), SIZE_TO_CONTENT]
  let popupWidth = size?[0] ?? SIZE_TO_CONTENT
  let function openClustersMenu(event) {
    modalPopupWnd.add(event.targetRect, {
      uid = "clusters_selector"
      size = [popupWidth, SIZE_TO_CONTENT]
      children = clusterSelector
      popupOffset = hdpx(5)
      popupHalign = ALIGN_LEFT
      fillColor = ControlBgOpaque
      borderColor = borderColor
      borderWidth = hdpx(1)
    })
  }
  return function clustersUi() {
    let clustersArr = queueClusters.value
      .filter(@(has, cluster) has && availableClusters.value.indexof(cluster) != null)
      .keys()
    let chosenText = availableClusters.value.len() == clustersArr.len() ? loc("quickMatch/Server/Any")
      : ", ".join(clustersArr.map(clusterLoc))
    let text = "{0}: {1}".subst(loc("quickMatch/Server"), chosenText)
    return {
      watch = [queueClusters, canChangeQueueParams, availableClusters]
      size = size
      children = canChangeQueueParams.value
        ? textButton(text, openClustersMenu, btnParams)
        : textButton(text, showCantChangeMessage, visualDisabledBtnParams)
    }
  }
})

return {
  mkClustersUi
}