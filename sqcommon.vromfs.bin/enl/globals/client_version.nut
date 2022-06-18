from "frp" import Watched, Computed

let { get_circuit } = require("app")
let { yup_version, exe_version } = require("%dngscripts/appInfo.nut")
let { get_updated_game_version, get_vromfs_dump_version } = require("vromfs")
let { Version } = require("%sqstd/version.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")

let updatedGameVersion = Watched(0)
let mainVromfsVersion = Watched(0)

let function updateVromsVersion(inBattle){
  if (inBattle)
    return

  // Otherwise the game won't able to login and receive the profile.
  // Moon circuit can't work versions
  // But we still need to test the embedded updater
  let isMoonCircuit = ["moon"].contains(get_circuit())
  updatedGameVersion(isMoonCircuit ? 0 : get_updated_game_version())

  mainVromfsVersion(get_vromfs_dump_version("content/enlisted/enlisted-game.vromfs.bin"))
}

isInBattleState.subscribe(updateVromsVersion)
updateVromsVersion(isInBattleState.value)

let maxVersionInt = Computed(@() max(
  (updatedGameVersion.value ?? 0),
  (mainVromfsVersion.value ?? 0),
  Version(exe_version.value ?? 0).toint(),
  Version(yup_version.value ?? 0).toint()
))

let maxVersionStr = Computed(@() Version(maxVersionInt.value).tostring() )

return {
  maxVersionInt
  maxVersionStr
}