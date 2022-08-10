from "%enlSqGlob/ui_library.nut" import *

let { isPlatformRelevant, platformId } = require("%dngscripts/platform.nut")
let dagor_fs = require("dagor.fs")
let dagor_sys = require("dagor.system")
let {startswith} = require("string")
let game_name = require("app").get_game_name()
let dainput = require("dainput2")

let controlsList = require_optional("content/{0}/config/{0}.controls_presets_list.nut".subst(game_name))
  ?? require_optional($"{game_name}/content/common/config/controls_presets_list.nut")
  ?? {}

if (controlsList?[platformId] == null)
   controlsList[platformId] <- [dainput.get_default_preset_prefix()]
let generation = Watched(0)
let nextGeneration = @() generation(generation.value + 1)
let haveChanges = mkWatched(persist, "haveChanges", false)

let function mkPresetNameFromPresetPath(path){
  let split = path.split("/")
  local preset_name = split[split.len()-1]
  preset_name = preset_name.replace($"{game_name}.", "")
  return preset_name
}


local locPreset = function(name) {
  name = name?.name ?? mkPresetNameFromPresetPath(name)
  return loc($"controls/preset_{name}", loc(name))
}

local Preset = class {
  name = null
  preset = null
  constructor(preset_, name_ = null){
    this.name = name_ ?? locPreset(preset_)
    this.preset = preset_
  }
  function tostring(){
    return this.name
  }
  function value(){
    return this
  }
}

let function gatherByBpath(path) {
  let use_realfs = (dagor_sys.DBGLEVEL > 0) ? true: false
  return dagor_fs.scan_folder({root=path, vromfs = true, realfs = use_realfs, recursive = false, files_suffix=".c0.preset.blk"})
    .map(@(v) startswith(v, "/") ? (v.slice(1)).replace(".c0.preset.blk", "") : v.replace(".c0.preset.blk", ""))
}
let function lowerCaseSubstringInList(substring, list){
  let lowerCaseSubstring = substring.tolower()
  foreach (v in list){
    let lowerCaseValue = v.tolower()
    if (lowerCaseValue.indexof(lowerCaseSubstring)!=null)
      return true
  }
  return false
}

let function gatherPresets(){
  local availablePresets = gatherByBpath("content/{0}/config".subst(game_name)).extend(gatherByBpath("content/common/config"))
  availablePresets = controlsList?[platformId]?.filter(@(v) lowerCaseSubstringInList(v, availablePresets)) ?? []
  return availablePresets.map(@(v) Preset(v))
}
let availablePresets = Watched(gatherPresets())

let getActionTags = memoize(@(action_handler)
  dainput.get_group_tag_str_for_action(action_handler).split(",").map(@(v) v.replace(" ","")).filter(@(v) v!=""))

const platform_suffix = "platform="
let function mkSubTagsFind(suffix){
  return memoize(function(action_handler){
    foreach (tag in getActionTags(action_handler)){
      if (startswith(tag, suffix)) {
        let tagData = tag.slice(suffix.len())
        return tagData.split("/").map(@(v) v.replace(" ","")).filter(@(v) v!="")
      }
    }
    return null
  })
}
let getSubTagsForPlatform = mkSubTagsFind(platform_suffix)
let isActionForPlatform = memoize(@(action_handler)
  isPlatformRelevant(getSubTagsForPlatform(action_handler) ?? [])
)

let function getActionsList() {
  let res = []
  let total = dainput.get_actions_count()
  for (local i = 0; i < total; i++) {
    let ah = dainput.get_action_handle_by_ord(i)
    if (dainput.is_action_internal(ah) || !isActionForPlatform(ah))
      continue
    let actionType = dainput.get_action_type(ah)
    if ([dainput.TYPEGRP_DIGITAL, dainput.TYPEGRP_AXIS, dainput.TYPEGRP_STICK].indexof(actionType & dainput.TYPEGRP__MASK) != null)
      res.append(ah)
  }
  return res
}

let importantGroups = Watched([ "Movement", "Weapon", "View", "Vehicle" ])

return {
  importantGroups
  generation
  nextGeneration
  haveChanges
  availablePresets
  locPreset
  Preset
  controlsList

  getActionsList
  getActionTags

  mkSubTagsFind
}
