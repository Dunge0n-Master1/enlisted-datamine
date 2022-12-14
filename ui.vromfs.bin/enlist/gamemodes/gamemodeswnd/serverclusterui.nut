from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, bigPadding, defTxtColor, titleTxtColor, midPadding, smallPadding, hoverTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { canChangeQueueParams, isInQueue } = require("%enlist/state/queueState.nut")
let { availableClusters, clusters, clusterLoc, isAutoCluster, ownCluster
} = require("%enlist/clusterState.nut")
let { isInSquad, isSquadLeader, squadSharedData } = require("%enlist/squad/squadState.nut")
let squadClusters = squadSharedData.clusters
let squadAutoCluster = squadSharedData.isAutoCluster
let { addPopup, removePopup } = require("%enlist/popup/popupsState.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let mkCheckbox = require("%ui/components/mkCheckbox.nut")


const CLUSTER_PANEL_UID = "clustersSelector"
const SELECTION_ERROR_UID = "groupSizePopup"
const NO_SERVER_ERROR = "noServerPopup"


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = hoverTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let fillBgColor = @(sf) sf != 0 ? 0xFF3B516A : 0xFF132438
let isLocalClusters = Computed(@() !isInSquad.value || isSquadLeader.value)


let function toggleServerSelection(server) {
  if (server in clusters.value) {
    if (clusters.value.len() <= 1)
      addPopup({
        id = NO_SERVER_ERROR
        text = loc("quickMatch/noServer")
        styleName = "error"
      })
    else
      clusters.mutate(@(v) delete v[server])
  }
  else
    clusters.mutate(@(v) v[server] <- true)
}


let mkServerBtn = @(server, txt, isAutoSelected = false) watchElemState(function(sf) {
  let isSelected = Computed(@() server in clusters.value)
  return {
    watch = isSelected
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    padding = [smallPadding, midPadding]
    color = fillBgColor(sf)
    onClick = @() isAutoSelected ? null : toggleServerSelection(server)
    gap = bigPadding
    children = [
      mkCheckbox(isSelected, !isAutoSelected, false)
      {
        rendObj = ROBJ_TEXT
        text = txt
      }.__update(isSelected.value ? titleTxtStyle
        : sf & S_HOVER ? hoverTxtStyle
        : defTxtStyle)
    ]
  }
})


let optimalServerButton = watchElemState(@(sf) {
  watch = [isAutoCluster, ownCluster]
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  color = fillBgColor(sf)
  padding = [smallPadding, midPadding]
  behavior = Behaviors.Button
  onClick = @() isAutoCluster(!isAutoCluster.value)
  gap = bigPadding
  children = [
    mkCheckbox(isAutoCluster)
    {
      rendObj = ROBJ_TEXT
      text = loc("quickMatch/Server/Optimal", { code = ownCluster.value })
    }.__update(isAutoCluster.value ? titleTxtStyle
      : sf & S_HOVER ? hoverTxtStyle
      : defTxtStyle)
  ]
})

let clusterSelector = @() {
  watch = [availableClusters, isAutoCluster, clusters]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    optimalServerButton
  ].extend(availableClusters.value.map(@(val)
    mkServerBtn(val, clusterLoc(val), isAutoCluster.value)))
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
    size = [colFull(4), SIZE_TO_CONTENT]
    popupOffset = 0
    padding = 0
    margin = [0, 0, midPadding, 0]
    popupHalign = ALIGN_LEFT
    popupBg = { rendObj = null }
    children = clusterSelector
  })
}

isInQueue.subscribe(@(_) modalPopupWnd.remove(CLUSTER_PANEL_UID))


let function clustersUi() {
  local server = ""
  if (isLocalClusters.value)
    server = isAutoCluster.value ? loc("quickMatch/Server/Optimal", { code = ownCluster.value })
      : availableClusters.value.len() == clusters.value.len() ? loc("quickMatch/Server/Any")
      : ", ".join(clusters.value.keys().map(@(val) clusterLoc(val)))
  else
    server = squadAutoCluster.value ? loc("quickMatch/Server/Optimal", { code = ownCluster.value })
      : availableClusters.value.len() == squadClusters.value.len() ? loc("quickMatch/Server/Any")
      : ", ".join(squadClusters.value.keys().map(@(val) clusterLoc(val)))
  let text = loc("quickMatch/curServers", { server })
  let btn = Bordered(text, isLocalClusters.value ? openClustersMenu : showCantChangeMessage,
    { btnWidth = flex() })
  return {
    watch = [ isLocalClusters, canChangeQueueParams, availableClusters, clusters, isAutoCluster,
      squadClusters, squadAutoCluster, ownCluster ]
    size = [flex(), SIZE_TO_CONTENT]
    children = btn
  }
}

return clustersUi
