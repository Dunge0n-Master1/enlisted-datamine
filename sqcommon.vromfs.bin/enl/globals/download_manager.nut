from "%sqstd/functools.nut" import *
from "frp" import *
let eventbus = require("eventbus")
let Log = require("%sqstd/log.nut")
let http = require("dagor.http")
let { logerr } = require("dagor.debug")

local log = Log()
//local dlog = log.dlog
log = log.with_prefix("[DOWNLOAD MANAGER] ")

let statusText = {
  [http.SUCCESS] = "SUCCESS",
  [http.FAILED] = "FAILED",
  [http.ABORTED] = "ABORTED",
}
let EVENT_HTTP_DOWNLOAD = "EVENT_HTTP_DOWNLOAD"

let HTTP_REQUESTED = persist("HTTP_REQUESTED", @() freeze({}))
let HTTP_READY = persist("HTTP_READY", @() freeze({}))
let HTTP_ABORTED = persist("HTTP_ABORTED", @() freeze({}))
let HTTP_FAILED = persist("HTTP_FAILED", @() freeze({}))

let downloadCache = persist("downloadCache", @() {})
let downloadStatus = Watched(downloadCache.map(@(_) HTTP_READY))

let function setDownloadStatusMul(statuses){
  downloadStatus(downloadStatus.value.__merge(statuses))
}
downloadStatus.whiteListMutatorClosure(setDownloadStatusMul)

let function setDownloadStatus(key, status){
  log("set status for", key)
  setDownloadStatusMul({[key] = status})
}

let downloadCacheGen = Watched(0)


let function setDownloadedFile(key, file){
  log("populate cache for", key)
  downloadCacheGen(downloadCacheGen.value+1)
  downloadCache.__update({[key] = file})
}


local function httpGetRequest(url, cache_key=null, callback=null){
  cache_key = cache_key ?? url
  log($"HTTP requested for' {cache_key}', url = {url}")
  http.request({ url, method = "GET", respEventId = EVENT_HTTP_DOWNLOAD, context=cache_key, callback})
}

eventbus.subscribe(EVENT_HTTP_DOWNLOAD, tryCatch(function(response){
  let { status = -1, http_code=-1} = response
  let cache_key = response.context
  log($"HTTP response for {cache_key}")
  //send_counter("download files response", 1, { http_code, status })
  if (status != http.SUCCESS) {
    if (status == http.ABORTED)
      setDownloadStatus(cache_key, HTTP_ABORTED)
    else if (status == http.FAILED)
      setDownloadStatus(cache_key, HTTP_FAILED)
    throw($"http status {statusText?[status]}")
  }
  if (http_code < 200 || 300 <= http_code) {
    setDownloadStatus(cache_key, HTTP_FAILED)
    throw($"http code {http_code}")
  }
  let result = response.body
  if (result == null) {
    logerr($"incorrect file downloaded, {cache_key}")
    throw("empty file")
  }
  log("successfully downloaded file for key", cache_key)
  setDownloadedFile(cache_key, result)
  setDownloadStatus(cache_key, HTTP_READY)
}, function(e) {
    //send_counter("download file error")
    log("ERROR DOWNLOADING", e)
  }
))

local function requestCachedFile(url, cache_key=null){
  cache_key = cache_key ?? url
  if (cache_key in downloadCache){
    return HTTP_READY
  }
  if (downloadStatus?[cache_key] == HTTP_REQUESTED)
    return HTTP_REQUESTED
  httpGetRequest(url, cache_key)
  setDownloadStatus(cache_key, HTTP_REQUESTED)
  return HTTP_REQUESTED
}

let function requestCachedFiles(urlAndCacheKeys, useCache = true){
  let toRequest = []
  let statuses = {}
  foreach (urlAndKey in urlAndCacheKeys) {
    let url = (typeof urlAndKey == "string") ? urlAndKey : urlAndKey.url
    let cache_key = urlAndKey?.cache_key ?? url

    if (useCache && cache_key in downloadCache){
      if (downloadStatus.value?[cache_key] != HTTP_READY)
        statuses[cache_key] <- HTTP_READY
    }
    else if (cache_key not in downloadCache && downloadStatus.value?[cache_key] != HTTP_REQUESTED) {
      toRequest.append({url, cache_key})
      statuses[cache_key] <- HTTP_REQUESTED
      break
    }
  }
  if (toRequest.len()==0)
    return HTTP_READY
  foreach (urlAndKey in toRequest)
    httpGetRequest(urlAndKey.url, urlAndKey.cache_key)
  setDownloadStatusMul(statuses)
  return HTTP_REQUESTED
}

let function getDownloadedFile(cache_key){
  log("get downloaded file by cache key", cache_key)
  let res = downloadCache?[cache_key]
  if (res==null){
    log("no file downloaded! files:", downloadCache.keys())
    log("statuses:", downloadStatus.value.keys())
  }
  return res
}

let UNUSED = @(...) null

let downloadStatusGen = Computed(function(prev){
  if (prev == FRP_INITIAL)
    return 0
  UNUSED(downloadStatus)
  return prev+1
})

return {
  requestCachedFile = kwarg(requestCachedFile)
  downloadStatus
  downloadStatusGen
  downloadCacheGen
  getDownloadedFile
  HTTP_READY
  HTTP_REQUESTED
  HTTP_FAILED
  HTTP_ABORTED
  requestCachedFiles
  downloadCache
}