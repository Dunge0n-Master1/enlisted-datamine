from "%enlSqGlob/ui_library.nut" import *

let { to_string } = require("json")
let { file } = require("io")
let { file_exists } = require("dagor.fs")
let { gen_default_profile, gen_tutorial_profiles } = require("%enlist/meta/clientApi.nut")
let { logerr } = require("dagor.debug")

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

let function saveProfileImpl(profile, fileName, folderName = "sq_globals") {
  local filePath = $"../prog/{folderName}/data/{fileName}"
  if (!file_exists(filePath))
    filePath = fileName
  let output = file(filePath, "wt+")
  output.writestring("return ");
  output.writestring(to_string(profile, true))
  output.close()
  console_print($"Saved to {filePath}")
}

let function saveOneProfile(profile, fileName, folderName = "sq_globals") {
  if (profile == null)
    return
  if (prepareProfileData(profile))
    saveProfileImpl(profile, fileName, folderName)
}

let function saveProfilePack(profiles, to_file) {
  if (profiles == null)
    return
  let isSuccess = profiles.findvalue(@(p) !prepareProfileData(p)) == null
  if (isSuccess)
    saveProfileImpl(profiles, to_file)
}


let defCampaigns = ["moscow", "berlin", "normandy", "tunisia", "stalingrad", "pacific"]
local defProfileArmies = []
foreach (campaign in defCampaigns)
  defProfileArmies = defProfileArmies.append($"{campaign}_allies", $"{campaign}_axis")

local consoleProgressId = 0
let function startProgress(title) {
  console_command("console.progress_indicator {0} \"{1}\"".subst(++consoleProgressId, title))
  return consoleProgressId
}
let stopProgress = @(id) console_command($"console.progress_indicator {id}")

console_register_command(function() {
  let prgId = startProgress("meta.genDevProfile")
  gen_default_profile("dev", defProfileArmies, function(res) {
    stopProgress(prgId)
    saveOneProfile(res?.defaultProfile, "dev_profile.nut", "enlisted_pkg_dev/game")
  })
}, "meta.genDevProfile")

console_register_command(function() {
  let prgId = startProgress("meta.genBotsProfile")
  gen_default_profile("bots", defProfileArmies, function(res) {
    stopProgress(prgId)
    saveOneProfile(res?.defaultProfile, "bots_profile.nut")
  })
}, "meta.genBotsProfile")

console_register_command(function() {
  let prgId = startProgress("meta.genTutorialProfiles")
  gen_tutorial_profiles(function(res) {
    stopProgress(prgId)
    saveProfilePack(res, "all_tutorial_profiles.nut")
  })
}, "meta.genTutorialProfiles")
