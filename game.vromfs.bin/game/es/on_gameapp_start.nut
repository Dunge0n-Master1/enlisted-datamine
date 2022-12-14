from "%sqstd/functools.nut" import *
import "%dngscripts/ecs.nut" as ecs
let {exit_game, switch_scene, get_matching_invite_data, app_is_offline_mode} = require("app")
let {get_arg_value_by_name, dgs_get_settings, get_all_arg_values_by_name} = require("dagor.system")
let isDedicated = require_optional("dedicated") != null
let { logerr } = require("dagor.debug")
let {EventOnGameAppStarted} = require("gameevents")
let Log = require("%sqstd/log.nut")
let {file} = require("io")
let {requestModFiles} = require("%enlSqGlob/game_mods.nut")
let log = Log().with_prefix("[GAME LOAD] ")
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

    let modHash = inviteData?.mode_info.modHash ?? get_arg_value_by_name("modHash") ?? ""
    let modId = inviteData?.mode_info.modId ?? ""
    let baseModsFilesUrl = inviteData?.mode_info.baseModsFilesUrl ?? get_arg_value_by_name("baseModsFilesUrl") ?? "https://enlisted-sandbox.gaijin.net"

    if (modHash=="") {
      let ugm_fname = get_arg_value_by_name("modFile") ?? ""
      local blob
      if (ugm_fname!="") {
        let f = file(ugm_fname, "rb")
        blob = f.readblob(f.len())
        f.close()
      }
      log($"no mod found, starting with scene = {scene}, ugm_fname = {ugm_fname}, importScenes = {",".join(importScenes ?? [])}")
      switch_scene(scene, importScenes, connect, blob, modId)
    }
    else {
      if (baseModsFilesUrl=="") {
        logerr("modHash should be specified with baseModsFilesUrl")
        exit_game()
      }

      requestModFiles(modHash, baseModsFilesUrl, function(vroms){
        log("vroms.ready", vroms?.len())
        if ((vroms?.len() ?? 0) < 1)
          throw($"no vroms loaded, switch_scene() call skipped: baseUrl={baseModsFilesUrl}, hashes={modHash}")
        let blob = vroms[0]
        log("BLOB TYPE:", type(blob), "blob len", blob?.len())
        if (blob != null)
          switch_scene("scene.blk", importScenes, connect, blob, modId)
        else
          throw("no data!")
      })
    }
  }
  else
    switch_scene("content/common/gamedata/scenes/empty.blk") // launch from enlist
}

ecs.register_es("on_gameapp_started_es",
  {
    [EventOnGameAppStarted] = on_gameapp_started,
  })
