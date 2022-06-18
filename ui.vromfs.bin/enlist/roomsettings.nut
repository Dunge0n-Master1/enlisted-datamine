from "%enlSqGlob/ui_library.nut" import *

let {startswith} = require("string")
let random = require("dagor.random")
let localSettings = require("options/localSettings.nut")("createRoom/")
let {get_setting_by_blk_path} = require("settings")
let {scan_folder} = require("dagor.fs")
let matchingGameName = get_setting_by_blk_path("matchingGameName")
let {dgs_get_settings} = require("dagor.system")
let {flatten} = require("%sqstd/underscore.nut")

let settings = {
  minPlayers = 1
  maxPlayers = 32
  roomName = "room_{0}".subst(random.rnd_int(1, 10000))
  startOffline = false
  botsPopulation = 0
  botAutoSquad = false
  writeReplay = false
  groupSize = 1
}.map(localSettings)

let scenesFolders = []
let scenesBlk = dgs_get_settings()?["scenes"]
if (scenesBlk!=null) {
  for (local i=0; i<scenesBlk.paramCount(); i++){
    scenesFolders.append(scenesBlk.getParamValue(i))
  }
}

let useAddonVromSrc = get_setting_by_blk_path("debug/useAddonVromSrc") ?? false
let lscenes = flatten(scenesFolders.map(@(v) scan_folder({root=v, vromfs = !useAddonVromSrc, realfs = useAddonVromSrc, recursive = true, files_suffix="*.blk"})
 .map(function(v){
    if (!v.contains("/scenes/") || v.contains("app_start.blk"))
      throw null
    let p = v.split("/")
    let fname = p[p.len()-1]
    if (startswith(fname, "_"))
      throw null
    return {title=fname, id=v}
   })
))

settings.savedSceneId <- localSettings("", "scene")
let game = Watched(matchingGameName)
let scenes = Computed(@() lscenes)
let scene = Watched(scenes.value
  .findvalue(@(s) s.id == settings.savedSceneId.value) ?? scenes.value?[0])

scene.subscribe(@(s) settings.savedSceneId(s?.id ?? ""))

settings.__update({game, scenes, scene})
return settings
