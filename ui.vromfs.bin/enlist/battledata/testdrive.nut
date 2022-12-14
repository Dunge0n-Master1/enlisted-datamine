from "%enlSqGlob/ui_library.nut" import *

let { gen_testdrive_squad_profile_jwt } = require("%enlist/meta/clientApi.nut")
let { mkJwtArmiesCbNoRetries, saveJwtResultToJson, setNextBattleData
} = require("sendSoldiersData.nut")
let { getTestDriveScene } = require("%enlist/configs/battleScenes.nut")
let { startGame } = require("%enlist/gameLauncher.nut")

let isTestDriveProfileInProgress = Watched(false)

let function startSquadTestDrive(armyId, squadId, shopItemGuid = "") {
  if (isTestDriveProfileInProgress.value)
    return
  isTestDriveProfileInProgress(true)
  gen_testdrive_squad_profile_jwt(armyId, squadId, shopItemGuid,
    mkJwtArmiesCbNoRetries(function(jwt, data) {
      isTestDriveProfileInProgress(false)
      if (jwt == "")
        return //we already have logerr in such case, so no need to do anything else
      setNextBattleData(armyId, jwt, data)
      startGame({ game = "enlisted", scene = getTestDriveScene(armyId) })
    }))
}

let saveSquadTestDriveToFile = @(armyId, squadId)
  gen_testdrive_squad_profile_jwt(armyId, squadId, "",
    mkJwtArmiesCbNoRetries(@(jwt, data) saveJwtResultToJson(jwt, data, "sendSquadTestDrive")))

console_register_command(saveSquadTestDriveToFile, "profileData.squadTestDriveToJson")

return {
  isTestDriveProfileInProgress
  startSquadTestDrive
}