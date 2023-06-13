from "%enlSqGlob/ui_library.nut" import *

let { getClusterByCode } = require("geo.nut")
let { get_country_code } = require("auth")
let dagor_sys = require("dagor.system")
let matching_api = require("matching.api")
let { matchingCall } = require("%enlist/matchingClient.nut")
let connectHolder = require("%enlist/connectHolderR.nut")
let { onlineSettingUpdated, settings } = require("%enlist/options/onlineSettings.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let { hasAutoCluster } = require("%enlist/featureFlags.nut")
let logC = with_prefix("[CLUSTERS] ")

const CLUSTERS_KEY = "selectedClusters"
const AUTO_CLUSTER_KEY = "autoCluster"
let availableClustersDef = ["EU", "RU", "US", "JP"]
let debugClusters = dagor_sys.DBGLEVEL != 0 ? ["debug"] : []

let eventbus = require("eventbus")

let clustersViewMap = { RU = "EEU" }
let clusterLoc = @(cluster) loc(clustersViewMap?[cluster] ?? cluster)
let countryLoc = @(country) loc($"country/{country}", country.toupper())

let ownCluster = nestWatched("ownCluster", null)
let ownCountry = nestWatched("ownCountry", null)

//set clusters from Matching
let matchingClusters = nestWatched("matchingClusters", [])
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
        logC("clusters from matching server", response.clusters)
        matchingClusters(response.clusters)
      }
    }
  )
}

matchingClusters.subscribe(function(v) {
  if (v.len() == 0)
    gui_scene.resetTimeout(5, fetchClustersFromMatching)
  logC("matchingClusters:", v)
})

eventbus.subscribe("matching.connectHolder.ready", @(...) fetchClustersFromMatching())
fetchClustersFromMatching()

matching_api.listen_notify("hmanager.notify_clusters_changed")
eventbus.subscribe("hmanager.notify_clusters_changed", function(...) { fetchClustersFromMatching() })

let availableClusters = Computed(function() {
  local available = matchingClusters.value.filter(@(v) v!="debug")
  if (available.len()==0)
    available = clone availableClustersDef
  return available.extend(debugClusters)
})

let function setOwnCluster() {
  local country_code = get_country_code()
  ownCountry(country_code.tolower())
  country_code = country_code.toupper()
  let localData = getClusterByCode({ code = country_code })
  let cluster = localData.cluster
  logC("country code:", country_code, "localData:", localData)
  ownCluster(cluster)
}

let function validateClusters(clusters, available) {
  logC("validate clusters:", clusters, "available:", available)
  clusters = clusters.filter(@(has, cluster) has && available.contains(cluster))
  if (clusters.len() == 0 && available.contains(ownCluster.value))
    clusters[ownCluster.value] <- true
  if (clusters.len() == 0 && available.len() > 0)
    clusters[available[0]] <- true
  logC("result clusters:", clusters)
  return clusters
}

let clusters = nestWatched("clusters", validateClusters({}, availableClusters.value))
let rawAutoCluster = nestWatched("autocluster", true)
let isAutoCluster = Computed(@() hasAutoCluster.value && rawAutoCluster.value)

onlineSettingUpdated.subscribe(function(v) {
  if (!v)
    return
  setOwnCluster()
  logC("onlineSettings auto:", settings.value?[AUTO_CLUSTER_KEY],"selectedClusters:", settings.value?[CLUSTERS_KEY])
  rawAutoCluster(settings.value?[AUTO_CLUSTER_KEY] ?? (clusters.value.len() <= 1))
  clusters(validateClusters(settings.value?[CLUSTERS_KEY] ?? {}, availableClusters.value))
})
setOwnCluster()
availableClusters.subscribe(function(available) {
  clusters(validateClusters(clusters.value, available))
})

let selectedClusters = Computed(function() {
  if (!isAutoCluster.value)
    return clone clusters.value
  let available = availableClusters.value
  let ownId = ownCluster.value
  if (available.contains(ownId))
    return { [ownCluster.value] = true }
  return { [available[0]] = true }
})

selectedClusters.subscribe(@(v)
  logC("auto:", isAutoCluster.value, "own:", ownCluster.value, "selectedClusters:", v))

let oneOfSelectedClusters = Computed(function() {
  foreach (c, has in selectedClusters.value)
    if (has)
      return c
  return matchingClusters.value?[0] ?? availableClustersDef[0]
})

clusters.subscribe(function(clustersVal) {
  let needSave = isEqual(settings.value?[CLUSTERS_KEY], clustersVal)
  logC("onlineSettingsUpdated:", onlineSettingUpdated.value, "isEqual to current:", needSave, "toSave:", clustersVal)
  if (!onlineSettingUpdated.value || needSave)
    return
  settings.mutate(@(s) s[CLUSTERS_KEY] <- clustersVal.filter(@(has) has))
})

isAutoCluster.subscribe(function(isAuto) {
  if (!onlineSettingUpdated.value || isAuto == settings.value?[AUTO_CLUSTER_KEY])
    return
  settings.mutate(@(s) s[AUTO_CLUSTER_KEY] <- isAuto)
})

return {
  ownCountry
  availableClusters
  clusters
  selectedClusters
  isAutoCluster
  oneOfSelectedClusters
  clusterLoc
  countryLoc
}
