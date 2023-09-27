from "frp" import *

let http = require("dagor.http")
let datacache = require_optional("datacache")
if (datacache == null)
  return {
    downloadMod = @(_url, _cbOnSuccess=null, _cbOnFailed=null) null
    removeMod = @(_mod_id) null
    loadModList = @() {}
    getModManifest = @(_mod_id) null
    getModStartInfo = @(_manifest, _contents) null
  }

let eventbus = require("eventbus")
let { file } = require("io")
let { logerr } = require("dagor.debug")
let { mkdir, file_exists, scan_folder } = require("dagor.fs")
let { parse_json } = require("json")
let { loadJson, saveJson } = require("%sqstd/json.nut")
let { remove = null } = require_optional("system")
let { get_setting_by_blk_path } = require("settings")
let { MOD_FILE_URL, USER_MODS_FOLDER, USER_MOD_MANIFEST_EXT } = require("%enlSqGlob/game_mods_constant.nut")
let logGM = require("%enlSqGlob/library_logs.nut").with_prefix("[ModsDownloadManager] ")
let {is_pc} = require("%dngscripts/platform.nut")
let USER_MOD_MANIFEST = "".concat(USER_MODS_FOLDER, "/{0}", USER_MOD_MANIFEST_EXT)

let statusText = {
  [http.HTTP_SUCCESS] = "SUCCESS",
  [http.HTTP_FAILED] = "FAILED",
  [http.HTTP_ABORTED] = "ABORTED",
}

let DATACACHE_ERROR_TO_TEXT = {
  [datacache.ERR_MEMORY_LIMIT] = "mods/memoryLimit",
  [datacache.ERR_ABORTED] = "mods/userAborted",
}

let storageLimitMB = get_setting_by_blk_path("mods/storageLimitMB") ?? 300

let isModsDatacacheInited = Watched(false)
let initModsDatacache = function() {
  if (isModsDatacacheInited.value)
    return
  datacache.init_cache("mods",
  {
    mountPath = "mods"
    maxSize = storageLimitMB << 20
    manualEviction = true
    timeoutSec = -1
  })
  isModsDatacacheInited(true)
}


local pendingFilesCount = 0
let modsCache = Watched({})
let modsContents = Watched({})


let function jsonSafeParse(v) {
  try
    return parse_json(v ?? "")
  catch(e)
    return null
}


let function readFile(filename) {
  let input = file(filename, "rt")
  let text = input.readblob(input.len()).as_string()
  input.close()
  return text
}

let function loadManifest(filename) {
  if (filename in modsCache.value)
    return modsCache.value[filename]

  let manifest = loadJson(filename, {load_text_file=readFile})
  modsCache.mutate(@(v) v[filename] <- manifest)
  return manifest
}


let function onReceiveFile(response) {
  logGM("onReceiveFile headers:", response?.headers)
  let { status, http_code, context = {} } = response
  let { cbOnSuccess, cbOnFailed } = context

  pendingFilesCount -= 1
  if (status != http.HTTP_SUCCESS || http_code == null || http_code >= 300 || http_code < 200) {
    logGM("onReceiveFile status =", status, statusText?[status], http_code)
    cbOnFailed(response)
    return
  }
  cbOnSuccess(response)
}


let function downloadFile(url, cbOnSuccess, cbOnFailed, context = {}) {
  http.request({
    method = "GET"
    callback = onReceiveFile
    url
    context = context.__merge({
      url
      cbOnSuccess
      cbOnFailed
    })
  })
  pendingFilesCount += 1
}


let function abortDownload() {
  initModsDatacache()
  datacache.abort_requests("mods")
  pendingFilesCount = 0
}


let function removeMod(mode_id) {
  initModsDatacache()
  if (remove == null) {
    logerr("Can't remove mod function remove doesn't exist for this VM!")
    return
  }

  let manifest_file_path = USER_MOD_MANIFEST.subst(mode_id)
  let manifest = loadManifest(manifest_file_path)
  if (file_exists(manifest_file_path))
    remove(manifest_file_path)
  if (manifest_file_path in modsCache)
    modsCache.mutate(@(v) delete v[manifest_file_path])
  if (manifest == null)
    return
  foreach(content in manifest?.content ?? {}) {
    let url = MOD_FILE_URL.subst(content.hash)
    datacache.del_entry("mods", url)
  }
}

let function downloadMod(url, cbOnSuccess=null, cbOnFailed=null) {
  mkdir(USER_MODS_FOLDER)
  initModsDatacache()
  let onManifestSuccessDownload = function(response) {
    local manifest = jsonSafeParse(response?.body?.as_string())
    if (manifest == null) {
      cbOnFailed("mods/InvalidManifest", 200)
      return
    }
    let manifest_file_path = USER_MOD_MANIFEST.subst(manifest.id)
    if (is_pc) {
      if (!saveJson(manifest_file_path, manifest)) {
        cbOnFailed("mods/FailedSaveManifest", 200)
        return
      }
    }
    else
      logGM("Skip save manifest for not PC platform")
    modsContents.mutate(@(v) v[manifest_file_path] <- {})
    foreach(content in manifest?.content ?? {}) {
      let contentHash = content.hash
      let contentUrl = MOD_FILE_URL.subst(contentHash)
      eventbus.subscribe_onehit($"datacache.{contentUrl}", function(result) {
        logGM("Finish download mod file: ", result, pendingFilesCount)
        pendingFilesCount -= 1
        if (result?.error) {
          abortDownload()
          removeMod(manifest.id)
          modsContents.mutate(@(v) delete v[manifest_file_path])
          cbOnFailed(DATACACHE_ERROR_TO_TEXT?[result?.error_code] ?? "mods/HttpError", 0)
          return
        }
        modsContents.mutate(@(v) v[manifest_file_path][contentHash] <- result.path)
        if (pendingFilesCount == 0) {
          cbOnSuccess(manifest, modsContents.value[manifest_file_path])
          modsCache.mutate(@(v) v[manifest_file_path] <- manifest)
        }
      })
      pendingFilesCount += 1
      datacache.request_entry("mods", contentUrl)
    }
  }

  let onManifsetFailedDownload = function(response) {
    cbOnFailed("mods/failedDownload", response.http_code)
  }

  downloadFile(url, onManifestSuccessDownload, onManifsetFailedDownload)
}


let function loadModList() {
  let mod_files = scan_folder({root = USER_MODS_FOLDER,
                               vromfs = false,
                               realfs = true,
                               recursive = false
                               files_suffix = USER_MOD_MANIFEST_EXT})
  let mods = {}
  foreach(mod_file in mod_files) {
    let manifest = loadManifest(mod_file)
    if (manifest && manifest?.id != null)
      mods[manifest.id] <- manifest.__merge({
        filename = mod_file
      })
  }
  return mods
}

let function getModManifest(mod_id) {
  let manifest_file_path = USER_MOD_MANIFEST.subst(mod_id)
  return loadManifest(manifest_file_path)
}

let function getModStartInfo(manifest, contents) {
  let mainVrom = manifest?.mainVrom ?? "";
  let modExtraVroms = []
  local scene = ""
  foreach (content in manifest.content) {
    let filename = content?.file ?? ""
    let path = contents?[content?.hash]
    if (path == null) {
      logerr($"Can't find mod content '{content?.hash}' in contents")
      continue
    }
    let isVrom = filename.endswith(".vromfs.bin")
    if (filename == mainVrom) {
      scene = path
      if (isVrom) {
        scene = $"%ugm/scene.blk"
        modExtraVroms.append(path)
      }
    } else if (isVrom)
      modExtraVroms.append(path)
    else
      logerr($"This file is not support as mod vromfs or scene: '{filename}' located in '{path}'")
  }

  return {
    scene
    modExtraVroms
  }
}


return {
  downloadMod
  removeMod
  loadModList
  getModManifest
  getModStartInfo
}
