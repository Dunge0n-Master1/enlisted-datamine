from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, bigPadding, defTxtColor, titleTxtColor, midPadding, smallPadding, hoverTxtColor,
  panelBgColor, hoverPanelBgColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { canChangeQueueParams, isInQueue } = require("%enlist/state/queueState.nut")
let { availableClusters, clusters, clusterLoc, isAutoCluster, ownCluster, hasAutoClusterOption,
  isAutoClusterSafe
} = require("%enlist/clusterState.nut")
let { isInSquad, isSquadLeader, squadSharedData } = require("%enlist/squad/squadState.nut")
let squadClustersWatched = squadSharedData.clusters
let squadAutoClusterWatched = squadSharedData.isAutoCluster
let { addPopup, removePopup } = require("%enlSqGlob/ui/popup/popupsState.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let mkCheckbox = require("%ui/components/mkCheckbox.nut")


const CLUSTER_PANEL_UID = "clustersSelector"
const SELECTION_ERROR_UID = "groupSizePopup"
const NO_SERVER_ERROR = "noServerPopup"


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = hoverTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = darkTxtColor }.__update(fontMedium)
let fillBgColor = @(sf) (sf & S_ACTIVE) != 0 || (sf & S_HOVER) != 0
  ? hoverPanelBgColor
  : panelBgColor
let isLocalClusters = Computed(@() !isInSquad.value || isSquadLeader.value)
let squadClusters = Computed(@() squadClustersWatched.value ?? {})
let squadAutoCluster = Computed(@() squadAutoClusterWatched.value ?? false)


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


let function mkServerBtn(server, txt, isAutoSelected = false) {
  let isSelected = Computed(@() server in clusters.value)
  return watchElemState(@(sf) {
    watch = [isSelected, isAutoCluster]
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
      }.__update(isSelected.value && !isAutoCluster.value ? titleTxtStyle
        : sf & S_HOVER ? hoverTxtStyle
        : defTxtStyle)
    ]
  })
}


let optimalServerButton = watchElemState(@(sf) {
  watch = [isAutoClusterSafe, ownCluster]
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
      text = loc("quickMatch/Server/Optimal", { code = clusterLoc(ownCluster.value) })
    }.__update(isAutoClusterSafe.value ? titleTxtStyle
      : sf & S_HOVER ? hoverTxtStyle
      : defTxtStyle)
  ]
})

let clusterSelector = @() {
  watch = [availableClusters, isAutoClusterSafe, clusters, hasAutoClusterOption]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    !hasAutoClusterOption.value ? null : optimalServerButton
  ].extend(availableClusters.value.map(@(val)
    mkServerBtn(val, clusterLoc(val), isAutoClusterSafe.value)))
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
    popupHalign = ALIGN_CENTER
    popupBg = { rendObj = null }
    children = clusterSelector
  })
}

isInQueue.subscribe(@(_) modalPopupWnd.remove(CLUSTER_PANEL_UID))


let serversRow = Computed(function() {
  if (isLocalClusters.value)
    return isAutoClusterSafe.value ? loc("quickMatch/Server/Optimal", { code = clusterLoc(ownCluster.value) })
      : availableClusters.value.len() == clusters.value.len() ? loc("quickMatch/Server/Any")
      : ", ".join(clusters.value.keys().map(@(val) clusterLoc(val)))
  return squadAutoCluster.value ? loc("quickMatch/Server/Optimal", { code = clusterLoc(ownCluster.value) })
    : availableClusters.value.len() == squadClusters.value.len() ? loc("quickMatch/Server/Any")
    : ", ".join(squadClusters.value.keys().map(@(val) clusterLoc(val)))
})


let function serverClusterBtn() {
  let text = loc("quickMatch/curServers", { server = serversRow.value })
  let btn = Bordered(text, isLocalClusters.value ? openClustersMenu : showCantChangeMessage,
    { sEnables = canChangeQueueParams.value })
  return {
    watch = [isLocalClusters, canChangeQueueParams, serversRow]
    children = btn
  }
}

let serversToShow = @(group = null) watchElemState(function(sf) {
  let text = availableClusters.value.len() == clusters.value.len()
    ? loc("quickMatch/Server/Any")
    : isAutoCluster.value ? loc("options/auto")
    : ", ".join(clusters.value.keys())
  return {
    watch = [isAutoCluster, clusters, availableClusters]
    size = [flex(), SIZE_TO_CONTENT]
    group
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("server")
      }.__update(sf & S_ACTIVE ? activeTxtStyle
        : sf & S_HOVER ? hoverTxtStyle
        : defTxtStyle)
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = {
          rendObj = ROBJ_TEXT
          text
        }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
      }
    ]
  }
})



return {
  serverClusterBtn
  serversToShow
}
