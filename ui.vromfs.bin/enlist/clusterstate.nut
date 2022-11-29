from "%enlSqGlob/ui_library.nut" import *

let { getClusterByCode } = require("geo.nut")
let platform = require("platform")
let dagor_sys = require("dagor.system")
let matching_api = require("matching.api")
let { matchingCall } = require("%enlist/matchingClient.nut")
let connectHolder = require("%enlist/connectHolderR.nut")
let { onlineSettingUpdated, settings } = require("%enlist/options/onlineSettings.nut")

const CLUSTERS_KEY = "selectedClusters"
const AUTO_CLUSTER_KEY = "autoCluster"
let availableClustersDef = ["EU", "RU", "US", "JP"]
let debugClusters = dagor_sys.DBGLEVEL != 0 ? ["debug"] : []

let notify = @(...) log.acall([null].extend(vargv))
let eventbus = require("eventbus")

let clustersViewMap = { RU = "EEU" }
let clusterLoc = @(cluster) loc(clustersViewMap?[cluster] ?? cluster)

//set clusters from Matching
let matchingClusters = mkWatched(persist, "matchingClusters", [])
let function fetchClustersFromMatching() {
  let self = callee()
  if (!connectHolder.is_logged_in()) {
    return
  }

  matchingCall("hmanager.fetch_clusters_list",
    function (response) {
      if (response.error != 0) {
        gui_scene.resetTimeout(5, self) //exponential backoff here needed
      }
      else {
        log("clusters from matching server", response)
        matchingClusters.update(response.clusters)
      }
    }
  )
}

matchingClusters.subscribe(function(v){
  if (v.len()==0)
    gui_scene.setTimeout(5, fetchClustersFromMatching)
})

eventbus.subscribe("matching.connectHolder.ready", @(...) fetchClustersFromMatching())
fetchClustersFromMatching()

matching_api.listen_notify("hmanager.notify_clusters_changed")
eventbus.subscribe("hmanager.notify_clusters_changed", function(...) { fetchClustersFromMatching() })
//set clusters from Matching
matchingClusters.subscribe(@(v) console_print("matchingClusters:", v) )

let availableClusters = Computed(function() {
  local available = matchingClusters.value.filter(@(v) v!="debug")
  if (available.len()==0)
    available = (clone availableClustersDef)
  return available.extend(debugClusters)
})

let function getOwnCluster() {
  let country_code = platform.get_locale_country().toupper()
  log("Country code:", country_code)
  let localData = getClusterByCode({ code = country_code })
  let cluster = localData.cluster
  log("own cluster:", cluster, "localData:", localData)
  return cluster
}

let ownCluster = getOwnCluster()

let function validateClusters(clusters, available) {
  notify("validate clusters. clusters:", clusters, "available:", available)
  clusters = clusters.filter(@(has, cluster) has && available.indexof(cluster)!=null)
  if (clusters.len() == 0 && available.indexof(ownCluster) != null)
      clusters[ownCluster] <- true
  if (clusters.len() == 0 && available.len() > 0)
    clusters[available[0]] <- true
  notify("result valid clusters:", clusters)
  return clusters
}

let clusters = mkWatched(persist, "clusters", validateClusters({}, availableClusters.value))
let isAutoCluster = mkWatched(persist, "autocluster", true)

onlineSettingUpdated.subscribe(function(v) {
  if (!v)
    return
  console_print("online selectedClusters:", settings.value?[CLUSTERS_KEY])
  clusters(validateClusters(settings.value?[CLUSTERS_KEY] ?? {}, availableClusters.value))
  isAutoCluster(settings.value?[AUTO_CLUSTER_KEY] ?? (clusters.value.len() <= 1))
})

availableClusters.subscribe(function(available) {
  clusters(validateClusters(clusters.value, available))
})

let selectedClusters = Computed(@() isAutoCluster.value
  ? { [ownCluster] = true }
  : clone clusters.value)

let oneOfSelectedClusters = Computed(function() {
  foreach (c, has in selectedClusters.value)
    if (has)
      return c
  return matchingClusters.value?[0] ?? availableClustersDef[0]
})

clusters.subscribe(function(clustersVal) {
  let needSave = isEqual(settings.value?[CLUSTERS_KEY], clustersVal)
  log("onlineSettingsUpdated:", onlineSettingUpdated.value, "isEqual to current:", needSave, "toSave:", clustersVal)
  if (!onlineSettingUpdated.value || needSave)
    return
  settings.mutate(@(s) s[CLUSTERS_KEY] <- clustersVal.filter(@(has) has))
})

isAutoCluster.subscribe(function(isAuto) {
  if (!onlineSettingUpdated.value
      || isAuto == settings.value?[AUTO_CLUSTER_KEY])
    return
  settings.mutate(@(s) s[AUTO_CLUSTER_KEY] <- isAuto)
})

return {
  availableClusters
  clusters
  selectedClusters = Computed(@() clone clusters.value) // Remove to enable autocluster feature
  isAutoCluster = Computed(@() false) // Remove to enable autocluster feature
  oneOfSelectedClusters
  clusterLoc
}
