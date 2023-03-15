from "%enlSqGlob/ui_library.nut" import *
let http = require("dagor.http")
let eventbus = require("eventbus")
let {scan_folder, file_exists, mkdir} = require("dagor.fs")
let { file } = require("io")
let { request_ugm_manifest } = require("game_load")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let { debounce } = require("%sqstd/timers.nut")
let json = require("json")
let regexp2 = require("regexp2")
let logGM = require("%enlSqGlob/library_logs.nut").with_prefix("[CustomGameMod] ")
let { send_counter } = require("statsd")
let { remove } = require("system")
let { showModsInCustomRoomCreateWnd } = require("%enlist/featureFlags.nut")
let { get_setting_by_blk_path } = require("settings")
let { deep_clone } = require("%sqstd/underscore.nut")


const USER_MODS_FOLDER = "userGameMods"
const MODS_EXT =".json"
const EVENT_RECEIVE_FILE_MOD = "EVENT_RECEIVE_FILE_MOD"
const BASE_URL = "https://enlisted-sandbox.gaijin.net/file/{0}"
const EVENT_MOD_VROM_INFO = "mod_info_vrom_loaded"
const EVENT_RECEIVE_MOD_MANIFEST = "EVENT_RECEIVE_MOD_MANIFEST"
const MOD_DOWNLOAD_URL = "https://sandbox.enlisted.net/post/{0}/manifest/{1}/"

let gameMods = mkWatched(persist, "gameMods", [])
let modPath = mkWatched(persist, "modPath", "")
let receivedModInfos = Watched({})
let noModInfo = freeze({ NoModeInfo = null })
let requestedFiles = Watched({})
let modDownloadShowProgress = Watched(false)
let modDownloadMessage = Watched("")
let hasBeenUpdated = Watched(false)

let isModAvailable = Computed(@()(get_setting_by_blk_path("isModAvailable") ?? true)
  && showModsInCustomRoomCreateWnd.value)

let availDomains = "({0})".subst("|".join([
  "enlisted-sandbox.gaijin.net"
  "enlisted-sandbox.gaijin.ops"
  "sandbox.enlisted.net"
].map(@(u) u.replace(".", @"\."))))
let reUrlPath = regexp2(@"^https?:\/\/{0}\/post\/\w{16}\/manifest\/.*\/$".subst(availDomains))

const FILE_REQUESTED = 0
const FILE_ERROR = 1
let statusText = {
  [http.SUCCESS] = "SUCCESS",
  [http.FAILED] = "FAILED",
  [http.ABORTED] = "ABORTED",
}

let function jsonSafeParse(v){
  if (v=="")
    return null
  try{
    return json.parse(v)
  }
  catch(e) {
    return null
  }
}

let function checkModFileByHash(hash){
  if (!file_exists($"{USER_MODS_FOLDER}/{hash}.bin"))
    return false
  return true
}

let isStrHash = @(hash) hash.len()==64
let getFname = @(mpath) mpath.split("/").top()

let function getFiles(){
  let res = {}
  let files = scan_folder({ root = USER_MODS_FOLDER,
                              vromfs = false,
                              realfs = true,
                              recursive = false
                              files_suffix = MODS_EXT })
  foreach (f in files){
    let hash = getFname(f).split(".")[0]
    if (!isStrHash(hash))//sha3_256 len
      continue
    res[hash] <- true
  }
  return res
}

let receivedFiles = Watched(getFiles())
let requestedManifest = Watched({})

let setHashError = @(hash) requestedFiles.mutate(@(v) v[hash] <- FILE_ERROR)

let function getFileExt(filename) {
  let extIndex = filename.indexof(".") ?? -1
  if (extIndex < 0)
    return ""
  return filename.slice(extIndex)
}

eventbus.subscribe(EVENT_RECEIVE_FILE_MOD, function(response){
  logGM("received headers:", response?.headers)
  let { hash, filename = "scene.blk" } = response?.context ?? {}
  if (hash == null) {
    logGM("unknown hash")
    modDownloadMessage("mods/UnknownHash")
    // todo: remove manifest
    return
  }
  let { status, http_code } = response
  if (status != http.SUCCESS || http_code == null || http_code >= 300 || http_code < 200) {
    logGM("request status =", status, statusText?[status], http_code)
    send_counter("event_file_mod_receive_error", 1, { http_code })
    setHashError(hash)
    modDownloadMessage("mods/failedDownload")
    // todo: remove manifest
    return
  }
  try {
    //save to disk
    let body = response?.body
    mkdir(USER_MODS_FOLDER)
    let fileName = $"{USER_MODS_FOLDER}/{hash}{getFileExt(filename)}"
    let resultFile = file(fileName, "wb+")
    resultFile.writeblob(body)
    resultFile.close()
    receivedFiles.mutate(@(v) v[hash] <- true)
    requestedFiles.mutate(function(v) {
      if (hash in v)
        delete v[hash]
    })
  }
  catch(e){
    logGM(e)
    setHashError(hash)
  }
  modDownloadMessage(loc("mods/downloadCompleted"))
  modDownloadShowProgress(false)
})

let function requestFilesByHashes(hashes){
  foreach (hash in hashes){
    if (hash in receivedFiles.value)
      continue

    if (checkModFileByHash(hash))
      receivedFiles.mutate(@(v) v[hash] <- true )
    let url = BASE_URL.subst(hash)
    if (requestedFiles.value ?[hash] == FILE_REQUESTED)
      continue
    requestedFiles.mutate(@(v) v[hash]<-FILE_REQUESTED)
    http.request({
      method = "GET"
      url
      respEventId = EVENT_RECEIVE_FILE_MOD
      context = {
        hash = hash
        filename = "scene.blk"
      }
    })
  }
}

let function updateModList() {
  let mods = scan_folder({  root = USER_MODS_FOLDER,
                              vromfs = false,
                              realfs = true,
                              recursive = false
                              files_suffix = MODS_EXT })
  gameMods(mods)
  foreach (m in mods) {
    let manifestFile = file(m, "rb")
    let manifest = jsonSafeParse(manifestFile.readblob(manifestFile.len())?.as_string())
    manifestFile.close()
    eventbus.send(EVENT_MOD_VROM_INFO, manifest)
  }
}

hasBeenUpdated.subscribe(@(v) v ? updateModList() : null)

eventbus.subscribe(EVENT_RECEIVE_MOD_MANIFEST, function(response) {
  logGM("EVENT_RECEIVE_MOD_MANIFEST headers:", response?.headers)
  local modId = response?.context
  requestedManifest.mutate(function(v) {
    if (modId in v)
      delete v[modId]
  })

  let { status, http_code } = response
  if (status != http.SUCCESS || http_code == null || http_code >= 300 || http_code < 200) {
    modDownloadMessage("mods/failedDownload")
    logGM("EVENT_RECEIVE_MOD_MANIFEST status =", status, statusText?[status], http_code)
    send_counter("event_manifest_mod_receive_error", 1, { http_code })
    return
  }

  local manifest = jsonSafeParse(response?.body?.as_string())
  if (manifest == null) {
    modDownloadMessage("mods/InvalidManifest")
    return
  }

  mkdir(USER_MODS_FOLDER)
  let manifest_file_path = $"{USER_MODS_FOLDER}/{manifest?.id}.json"
  try {
    let resultFile = file(manifest_file_path, "wb+")
    resultFile.writeblob(response?.body)
    resultFile.close()
  } catch(e) {
    logGM("Save manifest failed: ", e, manifest_file_path)
    modDownloadMessage("mods/FailedSaveManifest")
    return
  }
  eventbus.send(EVENT_MOD_VROM_INFO, manifest)
  let content = manifest.content[0]
  let hash = content.hash
  http.request({
    method = "GET"
    url = $"https://enlisted-sandbox.gaijin.net/file/{hash}"
    respEventId = EVENT_RECEIVE_FILE_MOD
    context = {
      hash = hash
      filename = content.file
    }
  })
  updateModList()
})

let function requestModManifest(modId) {
  if (modId in requestedManifest.value || modId == "" || modId == null)
    return
  modDownloadShowProgress(true)
  if (!reUrlPath.match(modId)) {
    modDownloadMessage("mods/InvalidUrlFormat")
    return
  }
  modDownloadMessage("")
  requestedManifest.mutate(@(v) v[modId] <- true )
  http.request({
    method = "GET"
    url = modId
    respEventId = EVENT_RECEIVE_MOD_MANIFEST
    context = modId
  })
}


eventbus.subscribe(EVENT_MOD_VROM_INFO, function(i) {
  let info = deep_clone(i)
  if (info?.id != null){
    if (info?.title != null)
      info.title = info.title.tostring()
    modPath(info.id)
    receivedModInfos.mutate(@(v) v[info.id] <- info)
  }
})


let function getModInfo(mpath) {
  let mod = receivedModInfos.value?[mpath]
  let {content = {}, contentId = null, manifest = null, modHash = null} = mod
  let titles = manifest?.title_localizations ?? {}
  titles.title <- manifest?.title ?? contentId
  let title = titles?[gameLanguage] ?? titles.title
  let fname = getFname(mpath).split(".")[0]
  let ext = getFileExt(content[0].file)

  local pathToStart = $"{USER_MODS_FOLDER}/{content[0].hash}.blk"
  if (ext == ".vromfs.bin")
    pathToStart = $"?{USER_MODS_FOLDER}/{content[0].hash}.vromfs.bin?.?scene.blk"
  return {contentId, pathToStart, title, titles, fname, modHash}
}


let requestUgmForCurMod = debounce(function(){
  let mpath = modPath.value
  request_ugm_manifest(mpath, EVENT_MOD_VROM_INFO)
}, 0.1)

modPath.subscribe(@(_) requestUgmForCurMod())
requestUgmForCurMod()

let function modName(v) {
  if ((v??"")=="")
    return loc("NO MOD")
  else{
    return getModInfo(v)?.title ?? $"Untitled file {getFname(v)}"
  }
}

let function getModPathToStart(){
  let mod = getModInfo(modPath.value)
  return mod?.pathToStart ?? ""
}


let function isSelectedModCorrect(){
  let mod = getModInfo(modPath.value)
  return (mod?.pathToStart != null) || mod == noModInfo
}

let function deleteMod(mod){
  let fileToDelete = $"{USER_MODS_FOLDER}/{mod}.json"
  if (mod == "" || !file_exists(fileToDelete))
    return
  let modToDelete = receivedModInfos.value.findindex(@(mods) mods.id == mod)
  receivedModInfos.mutate(@(receivedMods) delete receivedMods[modToDelete])
  remove(fileToDelete)
}

let allowChooseCampaign = Computed(@()
  receivedModInfos.value?[modPath.value].allowChooseCampaign ?? true)

let availableCampaigns = Computed(@()
  receivedModInfos.value?[modPath.value].room_params.defaults.public.campaigns ?? [])

return {
  hasBeenUpdated
  modPath
  gameMods
  modName
  isSelectedModCorrect
  getModPathToStart
  requestFilesByHashes
  receivedModInfos
  requestModManifest
  getModInfo
  modDownloadShowProgress
  modDownloadMessage
  deleteMod
  allowChooseCampaign
  availableCampaigns
  isModAvailable
  MOD_DOWNLOAD_URL
}