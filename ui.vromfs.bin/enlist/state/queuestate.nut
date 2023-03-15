from "%enlSqGlob/ui_library.nut" import *

let { isInSquad, isSquadLeader, squadSharedData } = require("%enlist/squad/squadState.nut")
let squadClusters = squadSharedData.clusters
let squadAutoCluster = squadSharedData.isAutoCluster
let { isAutoClusterSafe, selectedClusters } = require("%enlist/clusterState.nut")
let { matchingQueues } = require("%enlist/matchingQueues.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")


let STATUS = {
  NOT_IN_QUEUE = 0
  JOINING = 1
  IN_QUEUE = 2
}

let curQueueParam = nestWatched("curQueueParam", null)
let queueStatus = nestWatched("queueStatus", STATUS.NOT_IN_QUEUE)

let debugShowQueue = Watched(false)

let isInQueue = Computed(@() queueStatus.value != STATUS.NOT_IN_QUEUE || debugShowQueue.value)

let timeInQueue = Watched(0)
let queueClusters = Computed(@()
  isInSquad.value && !isSquadLeader.value && squadClusters.value != null
    ? clone squadClusters.value
    : clone selectedClusters.value) //clone to trigger change

let queueInfo = Watched(null)
let canChangeQueueParams = Computed(@() !isInQueue.value && (!isInSquad.value || isSquadLeader.value))

let availableSquadMaxMembers = Computed(@() matchingQueues.value.reduce(@(res, gt) max(res, (gt?.maxGroupSize ?? 1)), 1))

let function recalcSquadClusters(_) {
  if (!isSquadLeader.value)
    return
  squadClusters(clone selectedClusters.value)
  squadAutoCluster(isAutoClusterSafe.value)
}

foreach (w in [isSquadLeader, selectedClusters, isAutoClusterSafe])
  w.subscribe(recalcSquadClusters)

console_register_command(@() debugShowQueue(!debugShowQueue.value), "ui.showQueueInfo")

return {
  STATUS
  curQueueParam
  queueStatus
  isInQueue

  timeInQueue
  queueClusters

  queueInfo
  canChangeQueueParams

  availableSquadMaxMembers
}