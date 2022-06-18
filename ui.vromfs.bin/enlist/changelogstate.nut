from "%enlSqGlob/ui_library.nut" import *

let { send_error_log } = require("clientlog")
let { send_counter } = require("statsd")
let { mkVersionFromString, versionToInt } = require("%sqstd/version.nut")
let { language } = require("%enlSqGlob/clientState.nut")
let eventbus = require("eventbus")
let http = require("dagor.http")
let json = require("json")
let { exe_version } = require("%dngscripts/appInfo.nut")
let { onlineSettingUpdated, settings } = require("%enlist/options/onlineSettings.nut")
let { getPlatformId, getLanguageId } = require("httpPkg.nut")
let { get_setting_by_blk_path } = require("settings")
let { maxVersionInt } = require("%enlSqGlob/client_version.nut")

let changelogDisabled = get_setting_by_blk_path("disableChangelog") ?? false

local URL_VERSIONS = get_setting_by_blk_path("versionUrl") ?? ""
if(URL_VERSIONS == "")
  URL_VERSIONS = "https://enlisted.net/{0}/patchnotes/?page=1&platform={1}&target=enlisted_game"

local URL_PATCHNOTE = get_setting_by_blk_path("patchnoteUrl") ?? ""
if(URL_PATCHNOTE == "")
  URL_PATCHNOTE = "https://enlisted.net/{0}/patchnotes/patchnote/{2}?platform={1}&target=enlisted_game"

let function logError(event, params = {}) {
  log(event, params)
  send_error_log(event, {
    attach_game_log = true
    collection = "events"
    meta = {
      hint = "error"
      exe_version = exe_version.value
      language = language.value
    }.__update(params)
  })
}

const UseEventBus = true

const SAVE_ID = "ui/lastSeenVersionInfoNum"
const PatchnoteIds = "PatchnoteIds"

let lastSeenVersionInfoNumState = Computed(function() {
  if (!onlineSettingUpdated.value)
    return -1
  return settings.value?[SAVE_ID] ?? 0
})

let chosenPatchnote = Watched(null)
let chosenPatchnoteLoaded = mkWatched(persist, "chosenPatchnoteLoaded", false)
let chosenPatchnoteContent = mkWatched(persist, "chosenPatchnoteContent", "")
let chosenPatchnoteTitle = mkWatched(persist, "chosenPatchnoteTitle", "")
let patchnotesReceived = mkWatched(persist, "patchnotesReceived", false)
let versions = mkWatched(persist, "versions", [])

const maxVersionsAmount = 10

let function mkVersion(v){
  local tVersion = v?.version ?? ""
  let versionl = tVersion.split(".").len()
  local versionType = v?.type
  if (versionl!=4) {
    log($"incorrect patchnote version {tVersion}")
    if (versionl==3) {
      tVersion = $"{tVersion}.0"
      if (versionType==null)
        versionType = "major"
    }
    else
      throw null
  }
  let version = mkVersionFromString(tVersion)
  let title = v?.title ?? tVersion
  local titleshort = v?.titleshort ?? "undefined"
  if (titleshort=="undefined" || titleshort.len() > 50 )
    titleshort = null
  let date = v?.date ?? ""
  return {version, title, tVersion, versionType, titleshort, iVersion = versionToInt(version), id = v.id, date }
}

let function filterVersions(vers){
  let res = []
  local foundMajor = false
  foreach (idx, version in vers){
    if (idx >= maxVersionsAmount && foundMajor)
      break
    else if (maxVersionInt.value>0 && maxVersionInt.value < version.iVersion) {
      continue
    }
    else if (version.versionType=="major"){
      res.append(version)
      foundMajor=true
    }
    else if (idx < maxVersionsAmount && !foundMajor){
      res.append(version)
    }
  }
  return res
}

let function processPatchnotesList(response) {
  let { status = -1, http_code = 0, body = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("changelog_receive_errors", 1, { http_code, stage = "get_versions" })
    return
  }

  local result
  try {
    result = json.parse(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null) {
    logError("changelog_parse_errors", { stage = "get_versions" })
    send_counter("changelog_parse_errors", 1, { stage = "get_versions" })
    versions([])
    patchnotesReceived(false)
    return
  }

  log("changelog_success_versions", result)
  versions(filterVersions(result.map(mkVersion)))
  patchnotesReceived(true)
}

let function requestPatchnotes(){
  let request = {
    method = "GET"
    url = URL_VERSIONS.subst(getLanguageId(), getPlatformId())
  }
  if (UseEventBus)
    request.respEventId <- PatchnoteIds
  else
    request.callback <- processPatchnotesList
  patchnotesReceived(false)
  http.request(request)
}

let function isVersion(version){
  return type(version?.version) == "array" && type(version?.iVersion) == "integer" && type(version?.tVersion) == "string"
}

local function findBestVersionToshow(versionsList = versions, lastSeenVersionNum=0) {
  //here we want to find first unseen Major version or last unseed hotfix version.
  lastSeenVersionNum = lastSeenVersionNum ?? 0
  versionsList = versionsList ?? []
  foreach (version in versionsList) {
    if (lastSeenVersionNum < version.iVersion && version.versionType=="major"){
      return version
    }
  }
  local res = null
  foreach(version in versionsList)
    if (version.iVersion > lastSeenVersionNum)
      res = version
    else
      break
  return res
}

let unseenPatchnote = Computed(
  @() onlineSettingUpdated.value ? findBestVersionToshow(versions.value, lastSeenVersionInfoNumState.value) : null)
let curPatchnote = Computed(@() chosenPatchnote.value ?? unseenPatchnote.value ?? versions.value?[0])

let function markSeenVersion(v) {
  if (v == null)
    return
  if (v.iVersion > lastSeenVersionInfoNumState.value)
    settings.mutate(@(value) value[SAVE_ID] <- v.iVersion)
}

let updateVersion = @() markSeenVersion(curPatchnote.value)

const PatchnoteReceived = "PatchnoteReceived"

let patchnotesCache = persist("patchnotesCache", @() {})

let function setPatchnoteResult(result){
  chosenPatchnoteContent(result?.content ?? [])
  chosenPatchnoteTitle(result?.title ?? "")
  log("show patchnote:",result?.content)
  chosenPatchnoteLoaded(true)
  updateVersion()
}

let function cachePatchnote(response) {
  let { status = -1, http_code = 0, body = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("changelog_receive_errors", 1, { http_code, stage = "get_patchnote" })
  }

  local result
  try {
    result = json.parse(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null) {
    logError("changelog_parse_errors", { stage = "get_patchnote" })
    send_counter("changelog_parse_errors", 1, { stage = "get_patchnote" })
    return
  }

  log("changelog_success_patchnote")
  setPatchnoteResult(result)
  if (result?.id)
    patchnotesCache[result.id] <- result
}

let function requestPatchnote(v){
  if (v.id in patchnotesCache) {
    return setPatchnoteResult(patchnotesCache[v.id])
  }
  let request = {
    method = "GET"
    url = URL_PATCHNOTE.subst(getLanguageId(), getPlatformId(), v.id)
  }
  if (UseEventBus)
    request.respEventId <- PatchnoteReceived
  else
    request.callback <- cachePatchnote
  chosenPatchnoteLoaded(false)
  http.request(request)
}

if (UseEventBus) {
  eventbus.subscribe(PatchnoteIds, processPatchnotesList)
  eventbus.subscribe(PatchnoteReceived, cachePatchnote)
}

let curPatchnoteIdx = Computed( @() versions.value.indexof(curPatchnote.value) ?? 0)

let function haveUnseenMajorVersions(){
  let bestUnseenVersion = findBestVersionToshow(versions.value, lastSeenVersionInfoNumState.value)
  return (bestUnseenVersion != null && bestUnseenVersion.versionType == "major")
}

let function haveUnseenHotfixVersions(){
  let bestUnseenVersion = findBestVersionToshow(versions.value, lastSeenVersionInfoNumState.value)
  return (bestUnseenVersion != null && bestUnseenVersion.versionType != "major")
}

let haveUnseenVersions = Computed(@() unseenPatchnote.value != null)

let mkChangePatchNote = @(delta=1) function() {
  if (versions.value.len() == 0)
    return
  let nextIdx = clamp(curPatchnoteIdx.value-delta, 0, versions.value.len()-1)
  let patchnote = versions.value[nextIdx]
  chosenPatchnote(patchnote)
  requestPatchnote(patchnote)
}

let nextPatchNote = mkChangePatchNote()
let prevPatchNote = mkChangePatchNote(-1)

console_register_command(function() {
  if (SAVE_ID in settings.value)
    settings.mutate(@(v) delete v[SAVE_ID])
}, "changelog.reset")

return {
  changelogDisabled
  curPatchnote
  versions
  patchnotesReceived
  isVersion
  findBestVersionToshow
  haveUnseenHotfixVersions
  haveUnseenVersions
  haveUnseenMajorVersions
  curPatchnoteIdx
  nextPatchNote
  prevPatchNote
  updateVersion
  requestPatchnote
  chosenPatchnote
  chosenPatchnoteContent
  chosenPatchnoteTitle
  chosenPatchnoteLoaded
  requestPatchnotes
  maxVersionInt
}