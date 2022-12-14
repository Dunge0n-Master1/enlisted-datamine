from "%enlSqGlob/ui_library.nut" import *

let { ControlBgOpaque, BtnBgDisabled, BtnBdDisabled, BtnTextVisualDisabled, comboboxBorderColor
} = require("%ui/style/colors.nut")
let { canChangeQueueParams, isInQueue } = require("%enlist/state/queueState.nut")
let { availableClusters, clusters, clusterLoc, isAutoCluster, ownCluster, selectedClusters
} = require("clusterState.nut")
let { isInSquad, isSquadLeader, squadSharedData } = require("%enlist/squad/squadState.nut")
let squadClusters = squadSharedData.clusters
let squadAutoCluster = squadSharedData.isAutoCluster
let { addPopup, removePopup } = require("%enlist/popup/popupsState.nut")
let textButton = require("%ui/components/textButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { multiselect, styleCommon, styleDisabled } = require("%enlist/components/multiselect.nut")
let { hasClientPermission } = require("%enlSqGlob/client_user_rights.nut")
let serverDataPermission = hasClientPermission("debug_server_data")


const CLUSTER_PANEL_UID = "clustersSelector"
const SELECTION_ERROR_UID = "groupSizePopup"

let isLocalClusters = Computed(@() !isInSquad.value || isSquadLeader.value)

let btnParams = {
  size = [flex(), hdpx(50)]
  halign = ALIGN_LEFT
  margin = 0
  textMargin = [0, 0, 0, fsh(1.5)]
  clipChildren = true
  textParams = { behavior = Behaviors.Marquee }
}

let visualDisabledBtnParams = btnParams.__merge({
  style = {
    BgNormal = BtnBgDisabled
    BdNormal = BtnBdDisabled
    TextNormal = BtnTextVisualDisabled
  }
})

let clusterSelector = @() {
  watch = [availableClusters, isAutoCluster, clusters, selectedClusters, serverDataPermission]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = {
    size = [flex(), hdpx(1)]
    rendObj = ROBJ_SOLID
    color = comboboxBorderColor
  }
  children = [
    multiselect({
      selected = isAutoCluster.value ? Watched({}) : clusters
      minOptions = 1
      options = availableClusters.value.map(@(key) { key, text = clusterLoc(key) })
      style = isAutoCluster.value ? styleDisabled : styleCommon
    })
  ]
}

let showCantChangeInQueue = @() addPopup({
  id = SELECTION_ERROR_UID
  text = loc("quickMatch/paramsInQue")
  styleName = "error"
})

let function showCantChangeMessage() {
  if (isInQueue.value) {
    showCantChangeInQueue()
    return
  }
  addPopup({
    id = SELECTION_ERROR_UID
    text = loc("quickMatch/squadLeaderParams")
    styleName = "error"
  })
}

let function openClustersMenu(event) {
  if (isInQueue.value) {
    showCantChangeInQueue()
    return
  }
  removePopup(SELECTION_ERROR_UID)
  modalPopupWnd.add(event.targetRect, {
    uid = CLUSTER_PANEL_UID
    size = [hdpx(500), SIZE_TO_CONTENT]
    children = clusterSelector
    popupOffset = hdpx(5)
    popupHalign = ALIGN_LEFT
    fillColor = ControlBgOpaque
    borderColor = comboboxBorderColor
    borderWidth = hdpx(1)
  })
}

isInQueue.subscribe(@(_) modalPopupWnd.remove(CLUSTER_PANEL_UID))

let function mkClustersText(availClusters, curClusters, isAuto, code) {
  let clustersArr = availClusters.filter(@(id) curClusters?[id])
  let chosenText = isAuto ? loc("quickMatch/Server/Optimal", { code })
    : availClusters.len() == clustersArr.len() ? loc("quickMatch/Server/Any")
    : ", ".join(clustersArr.map(clusterLoc))
  return "{0}: {1}".subst(loc("quickMatch/Server"), chosenText)
}

let function clustersUi() {
  if (isLocalClusters.value) {
    let text = mkClustersText(availableClusters.value, clusters.value,
      isAutoCluster.value, ownCluster.value)
    return {
      watch = [isLocalClusters, canChangeQueueParams, availableClusters,
        clusters, isAutoCluster, ownCluster]
      size = [flex(), SIZE_TO_CONTENT]
      children = textButton(text, openClustersMenu,
        canChangeQueueParams.value ? btnParams : visualDisabledBtnParams)
    }
  }

  let text = mkClustersText(availableClusters.value, squadClusters.value,
    squadAutoCluster.value, ownCluster.value)
  return {
    watch = [isLocalClusters, availableClusters, squadClusters, squadAutoCluster, ownCluster]
    size = [flex(), SIZE_TO_CONTENT]
    children = textButton(text, showCantChangeMessage, visualDisabledBtnParams)
  }
}

return clustersUi
