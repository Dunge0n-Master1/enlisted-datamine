from "%sqstd/functools.nut" import *
import "%dngscripts/ecs.nut" as ecs
let {exit_game, switch_scene, get_matching_invite_data, app_is_offline_mode} = require("app")
let {get_arg_value_by_name, dgs_get_settings, get_all_arg_values_by_name} = require("dagor.system")
let isDedicated = require_optional("dedicated") != null
let { logerr } = require("dagor.debug")
let {EventOnGameAppStarted} = require("gameevents")
let Log = require("%sqstd/log.nut")
let {MOD_BY_VERSION_URL = ""} = require_optional("%enlSqGlob/game_mods_constant.nut")
let log = Log().with_prefix("[GAME LOAD] ")
let modsDownloadManager = require_optional("%enlSqGlob/modsDownloadManager.nut")
//local dlog = log.dlog

let function on_gameapp_started() {
  let settings = dgs_get_settings()
  local connect = isDedicated ? [] : get_all_arg_values_by_name("connect")
  connect = connect.len()>0 ? connect : null

  if (isDedicated || settings?.disableMenu || app_is_offline_mode() || connect != null) {
    let inviteData = get_matching_invite_data()
    log("inviteData", inviteData)

    let scene = get_arg_value_by_name("scene") ?? settings?.scene
    local importScenes = inviteData?.mode_info.imports
    if (importScenes==null){
      importScenes = get_all_arg_values_by_name("importScene")
      importScenes =  importScenes.len()>0 ? importScenes : null
    }

    let modId = inviteData?.mode_info.modId ?? ""
    let modVersion = inviteData?.mode_info.modVersion ?? "1"

    if (modId=="") {
      log($"no mod found, starting with scene = {scene}, importScenes = {",".join(importScenes ?? [])}")
      switch_scene(scene, importScenes, connect, modId)
    }
    else if (MOD_BY_VERSION_URL != "" && modsDownloadManager != null) {
      let modUrl = MOD_BY_VERSION_URL.subst(modId, modVersion)
      modsDownloadManager.downloadMod(modUrl, function(manifest, contents) {
        let modStartInfo = modsDownloadManager.getModStartInfo(manifest, contents)
        log("modStartInfo", modStartInfo)
        switch_scene(modStartInfo.scene, importScenes, connect, modId, modStartInfo.modExtraVroms)
      }, function(error_msg, http_code) {
        logerr($"Failed to download mode '{modUrl}' error = '{error_msg}', http: {http_code}")
        exit_game()
      })
    } else
      log($"Failed to load mods MOD_BY_VERSION_URL = '{MOD_BY_VERSION_URL}', modsDownloadManager = {modsDownloadManager}")
  }
  else
    switch_scene("content/common/gamedata/scenes/empty.blk") // launch from enlist
}

ecs.register_es("on_gameapp_started_es",
  {
    [EventOnGameAppStarted] = on_gameapp_started,
  })
