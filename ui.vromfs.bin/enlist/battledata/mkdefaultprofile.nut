from "%enlSqGlob/ui_library.nut" import *

let json = require("json")
let io = require("io")

let { gen_default_profile, gen_tutorial_profiles } = require("%enlist/meta/clientApi.nut")
let {logerr} = require("dagor.debug")

let function prepareProfileData(profile) {
  foreach (armyData in profile) {
    if (armyData?["armyProgress"] != null)
      delete armyData?["armyProgress"]
  }

  local isSuccess = true
  foreach (armyId, armyData in profile) {
    foreach (squad in armyData.squads) {
      if ((squad?.squad ?? []).len() == 0) {
        isSuccess = false
        logerr($"Squad '{squad.squadId}' in army '{armyId}' is empty! Please fix the squad in profileServer configs.")
      }
    }
  }
  return isSuccess
}

let function saveProfileImpl(profile, to_file, folder_name = "") {
  let file = io.file($"../prog/enlisted/{folder_name}/game/data/{to_file}", "wt+")
  file.writestring("return ");
  file.writestring(json.to_string(profile, true))
  file.close()
  console_print($"Saved to {to_file}")
}

let function saveOneProfile(profile, to_file, folder_name = "") {
  if (profile == null)
    return
  if (prepareProfileData(profile))
    saveProfileImpl(profile, to_file, folder_name)
}

let function saveProfilePack(profiles, to_file) {
  if (profiles == null)
    return
  let isSuccess = profiles.findvalue(@(p) !prepareProfileData(p)) == null
  if (isSuccess)
    saveProfileImpl(profiles, to_file)
}


let defCampaigns = ["moscow", "berlin", "normandy", "tunisia", "stalingrad"]
local defProfileArmies = []
foreach (campaign in defCampaigns)
  defProfileArmies = defProfileArmies.append($"{campaign}_allies", $"{campaign}_axis")

console_register_command(@()
  gen_default_profile("dev", defProfileArmies,
    @(res) saveOneProfile(res?.defaultProfile, "dev_profile.nut", "enlisted_pkg_dev")),
  "meta.genDevProfile")

console_register_command(@()
  gen_default_profile("bots", defProfileArmies,
    @(res) saveOneProfile(res?.defaultProfile, "bots_profile.nut")),
  "meta.genBotsProfile")

console_register_command(@()
  gen_tutorial_profiles(@(res) saveProfilePack(res, "all_tutorial_profiles.nut")),
  "meta.genTutorialProfiles")
