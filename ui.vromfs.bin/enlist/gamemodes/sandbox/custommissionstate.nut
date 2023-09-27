from "%enlSqGlob/ui_library.nut" import *
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let regexp2 = require("regexp2")
let { send_counter } = require("statsd")
let { showModsInCustomRoomCreateWnd } = require("%enlist/featureFlags.nut")
let { get_setting_by_blk_path } = require("settings")
let { MOD_DOMAIN_NAME, MOD_BY_VERSION_URL } = require("%enlSqGlob/game_mods_constant.nut")
let { downloadMod, removeMod, loadModList, getModManifest } = require("%enlSqGlob/modsDownloadManager.nut")

let modPath = mkWatched(persist, "modPath", "")
let receivedModInfos = Watched({})
let noModInfo = freeze({ NoModeInfo = null })
let modDownloadShowProgress = Watched(false)
let modDownloadMessage = Watched("")
let hasBeenUpdated = Watched(false)

let isModAvailable = Computed(@()(get_setting_by_blk_path("isModAvailable") ?? true)
  && showModsInCustomRoomCreateWnd.value)

let availDomains = "({0})".subst("|".join([
  "enlisted-sandbox.gaijin.net"
  "enlisted-sandbox.gaijin.ops"
  "sandbox.enlisted.net"
  MOD_DOMAIN_NAME
].map(@(u) u.replace(".", @"\."))))
let reUrlPath = regexp2(@"^https?:\/\/{0}\/post\/\w{16}\/manifest\/.*\/$".subst(availDomains))

let getFname = @(mpath) mpath.split("/").top()

let fileDownloadQueue = Watched({})

fileDownloadQueue.subscribe(function(v) {
  if (modDownloadShowProgress.value && v.len() == 0) {
    modDownloadMessage(loc("mods/downloadCompleted"))
    modDownloadShowProgress(false)
  }
})

let function updateModList() {
  receivedModInfos(loadModList())
  let keys = receivedModInfos.value.keys()
  if (keys.len() != 0) {
    modPath(keys[keys.len() - 1])
  }
}

hasBeenUpdated.subscribe(@(v) v ? updateModList() : null)

let function requestModManifest(modId, cbOnSuccess = null, cbOnFailed = null) {
  if (modId == "" || modId == null)
    return

  if (!reUrlPath.match(modId)) {
    modDownloadMessage("mods/InvalidUrlFormat")
    return
  }

  modDownloadShowProgress(true)
  modDownloadMessage("")
  downloadMod(modId, function(manifest, contents) {
    modDownloadShowProgress(false)
    updateModList()
    if (cbOnSuccess) {
      cbOnSuccess(manifest, contents)
    }
  }, function(error_msg, http_code) {
    modDownloadMessage(error_msg)
    send_counter("event_file_mod_receive_error", 1, { http_code })
    if (cbOnFailed) {
      cbOnFailed()
    }
  })
}

let function fetchLocalModById(mod_id, cbOnSuccess = null, cbOnFailed = null) {
  let manifest = getModManifest(mod_id)
  if (manifest == null) {
    modDownloadMessage("mods/FailedLoadManifest")
    return
  }
  let url = MOD_BY_VERSION_URL.subst(mod_id, manifest.version)
  requestModManifest(url, cbOnSuccess, cbOnFailed)
}

let function getModInfo(mpath) {
  let mod = receivedModInfos.value?[mpath]
  let {contentId = null, manifest = null, modHash = null} = mod
  let titles = manifest?.title_localizations ?? {}
  titles.title <- manifest?.title ?? contentId
  let title = titles?[gameLanguage] ?? titles.title
  let fname = getFname(mpath).split(".")[0]

  return {contentId, title, titles, fname, modHash}
}

let function modName(v) {
  if ((v??"")=="")
    return loc("NO MOD")
  else{
    return getModInfo(v)?.title ?? $"Untitled file {getFname(v)}"
  }
}

let function isSelectedModCorrect(){
  let mod = getModInfo(modPath.value)
  return (mod?.pathToStart != null) || mod == noModInfo
}

let function deleteMod(mod_id){
  removeMod(mod_id)
  receivedModInfos.mutate(@(receivedMods) delete receivedMods[mod_id])
}

let allowChooseCampaign = Computed(@()
  receivedModInfos.value?[modPath.value].allowChooseCampaign ?? true)

let availableCampaigns = Computed(@()
  receivedModInfos.value?[modPath.value].room_params.defaults.public.campaigns ?? [])

return {
  hasBeenUpdated
  modPath
  modName
  isSelectedModCorrect
  receivedModInfos
  requestModManifest
  modDownloadShowProgress
  modDownloadMessage
  deleteMod
  allowChooseCampaign
  availableCampaigns
  isModAvailable
  fetchLocalModById
}