import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[CPTC] ")
let contentUpdater = require_optional("contentUpdater")
if (contentUpdater == null) {
  debug("Not available")
  return
}

let { Version } = require("%sqstd/version.nut")
let { get_remote_version_async } = require("vromfsUpdate")
let { get_updated_game_version } = require("vromfs")

let {
  start_updater, stop_updater, is_updater_running,
  UPDATER_EVENT_STAGE,
  UPDATER_EVENT_PROGRESS,
  UPDATER_EVENT_ERROR,
  UPDATER_EVENT_FINISH,
  UPDATER_RESULT_SUCCESS
} = contentUpdater

let {isInBattleState} = require("%enlSqGlob/inBattleState.nut")
let {isLoggedIn} = require("%enlSqGlob/login_state.nut")

let isGetVersionInProgress = mkWatched(persist, "isGetVersionInProgress", false)

let remoteVromsVersion = mkWatched(persist, "remoteVromsVersion")
let remoteVromsVersionNumber = mkWatched(persist, "remoteVromsVersionNumber")
let downloadedVersion = mkWatched(persist, "downloadedVersion", Version(get_updated_game_version()).tostring())

let eventbus = require("eventbus")

let {get_circuit_conf} = require("app")
let {get_setting_by_blk_path} = require("settings")

let disableVromsAutoUpdate = get_circuit_conf()?.disableVromsAutoUpdate ?? false
let useAddonVromSrc        = get_setting_by_blk_path("debug/useAddonVromSrc") ?? false
let offlineBinaries        = get_setting_by_blk_path("debug/offlineBinaries") ?? false
let disableNetwork         = get_setting_by_blk_path("debug/disableNetwork") ?? false

let updaterEvents = {
  [UPDATER_EVENT_STAGE]    = @(_evt) null,
  [UPDATER_EVENT_PROGRESS] = @(_evt) null,
  [UPDATER_EVENT_FINISH]   = function(evt) {
    let {result, version} = evt;
    if (result == UPDATER_RESULT_SUCCESS)
      downloadedVersion(version)
  },
  [UPDATER_EVENT_ERROR]    = @(_evt) null,
}

const ContentUpdaterEventId = "contentUpdater.event"

eventbus.subscribe(ContentUpdaterEventId, function (evt) {
  let {eventType} = evt
  updaterEvents?[eventType](evt)
})

eventbus.subscribe("auth.get_remote_version_async", function(resp) {
  if (isInBattleState.value)
    return

  let version       = resp?.version
  let versionNumber = resp?.versionNumber

  isGetVersionInProgress(false)

  debug($"remote: {version} ({versionNumber}); downloaded: {downloadedVersion.value}")

  if (versionNumber == null || version == null || downloadedVersion.value == version)
    return

  remoteVromsVersion(version)
  remoteVromsVersionNumber(versionNumber)

  debug($"Start download a new version: {version}")
  start_updater(ContentUpdaterEventId)
})

let function update() {
  if (!isLoggedIn.value || isGetVersionInProgress.value || is_updater_running() || isInBattleState.value)
    return

  isGetVersionInProgress(true)
  get_remote_version_async()
}

if (!disableVromsAutoUpdate && !offlineBinaries && !useAddonVromSrc && !disableNetwork) {
  isInBattleState.subscribe(function(inBattle) {
    if (inBattle) {
      debug($"Stop due to the battle")
      stop_updater()
    }
    else {
      debug($"Return from the battle. Try to update the game.")
      update()
    }
  })

  ecs.register_es("content_updater_es",
    { onUpdate = @(...) update() },
    {},
    { tags="gameClient", updateInterval = 1800.0 /* 30 min */, after="*", before="*" })
}
else
  debug($"Disable update due to disableVromsAutoUpdate = {disableVromsAutoUpdate}; offlineBinaries = {offlineBinaries}; useAddonVromSrc = {useAddonVromSrc}; disableNetwork = {disableNetwork};")

console_register_command(@() update(), "updater.start")
