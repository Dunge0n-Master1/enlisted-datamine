import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let json = require("json")
let io = require("io")
let { decode } = require("jwt")
let eventbus = require("eventbus")
let { mkCmdProfileJwtData } = require("%enlSqGlob/sqevents.nut")
let { playerSelectedSquads, allAvailableArmies, curArmy } = require("%enlist/soldiers/model/state.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { isEventRoom } = require("%enlist/mpRoom/enlRoomState.nut")
let { myArmy } = require("%enlist/mpRoom/myRoomMemberParams.nut")
let {debug, logerr} = require("dagor.debug")
let { get_profile_data_jwt, debug_apply_booster_in_battle
} = require("%enlist/meta/clientApi.nut")
let {profilePublicKey} = require("%enlSqGlob/data/profile_pubkey.nut")

let nextBattleData = Watched(null)

let function decodeJwtAndHandleErrors(data) {
  let jwt        = data?.jwt ?? ""
  let jwtDecoded = decode(jwt, profilePublicKey)

  let jwtArmies = jwtDecoded?.payload.armies
  let jwtError = jwtDecoded?.error
  if (jwtArmies != null && jwtError == null)
    return {jwt, jwtArmies}

  log(data)

  logerr($"Error '{jwtError}' during jwt profile decoding. See log for more details.")

  return null
}

let function requestProfileDataJwt(armies, cb, triesCount = 0) {
  if (armies.len() <= 0)
    return

  let armiesToCurSquad = {}
  foreach (armyId in armies)
    armiesToCurSquad[armyId] <- playerSelectedSquads.value?[armyId] ?? ""

  local triesLeft = triesCount
  let cbWrapper = function(data) {
    let res = decodeJwtAndHandleErrors(data)
    if (res != null) {
      let {jwt, jwtArmies} = res
      cb(jwt, jwtArmies)
      return
    }

    if (--triesLeft >= 0) {
      debug($"Try again to get profile jwt. Tries left: {triesLeft}.")
      get_profile_data_jwt(armiesToCurSquad, callee())
    }
    else // Fail
      cb("", {})
  }

  get_profile_data_jwt(armiesToCurSquad, cbWrapper)
}

let function splitStringBySize(str, maxSize) {
  assert(maxSize > 0)
  let result = []
  local start = 0
  let len = str.len()
  while (start < len) {
    let pieceSize = min(len - start, maxSize)
    result.append(str.slice(start, start + pieceSize))
    start += pieceSize
  }
  return result
}

const TRIES_TO_REQUEST_PROFILE = 1

let function send(playerEid, jwt, data) {
  ecs.client_send_event(playerEid, mkCmdProfileJwtData({ jwt = splitStringBySize(jwt, 4096) }))
  eventbus.send("updateArmiesData", data)
}

let function requestAndSend(playerEid, teamArmy) {
  requestProfileDataJwt([teamArmy], @(jwt, data) send(playerEid, jwt, data),
    TRIES_TO_REQUEST_PROFILE)
}

local function saveJwtResultToJson(jwt, data, fileName, pretty = true) {
  fileName = $"{fileName}.json"
  local file = io.file(fileName, "wt+")
  file.writestring(json.to_string(data, pretty))
  file.close()
  console_print($"Saved json payload to {fileName}")
  fileName = $"{fileName}.jwt"
  file = io.file(fileName, "wt+")
  file.writestring(jwt)
  file.close()
  console_print($"Saved jwt to {fileName}")
}

let function saveToFile(teamArmy = null, pretty = true) {
  let cb = @(jwt, data) saveJwtResultToJson(jwt, data, "sendArmiesData", pretty)
  if (teamArmy == null) {
    let requestArmies = []
    foreach (armies in allAvailableArmies.value)
      requestArmies.extend(armies)
    requestProfileDataJwt(requestArmies, cb)
  }
  else
    requestProfileDataJwt([teamArmy], cb)
}

let mkJwtArmiesCbNoRetries = @(cb) function(data) {
  let res = decodeJwtAndHandleErrors(data)
  if (res == null) {// Fail
    cb("", {})
    return
  }
  let {jwt, jwtArmies} = res
  cb(jwt, jwtArmies)
}

let findArmy = @(armies, allArmies) armies.findvalue(@(a) allArmies.contains(a))

eventbus.subscribe("requestArmiesData", function(msg) {
  let { armies, playerEid } = msg
  if (armies.contains(nextBattleData.value?.armyId))
    send(playerEid, nextBattleData.value.jwt, nextBattleData.value.data)
  else {
    let selArmyId = isEventRoom.value ? myArmy.value : curArmy.value
    local armyId = armies.findvalue(@(a) a == curArmy.value)
      ?? findArmy(armies, allAvailableArmies.value?[curCampaign.value] ?? [])
    log($"[ARMY_DATA] request army data for army {armyId} (selArmy = {selArmyId})")
    if (armyId == null)
      foreach (list in allAvailableArmies.value) {
        armyId = findArmy(armies, list)
        if (armyId != null)
          break
      }
    if (armyId == null)
      logerr("requestArmiesData: no available armies in requested armies. armies = [{0}]".subst(", ".join(armies)))

    requestAndSend(playerEid, armyId ?? curArmy.value ?? armies[0])
  }
  nextBattleData(null)
})

let function debugApplyBoosterInBattle() {
  let armyId = curArmy.value
  requestProfileDataJwt([armyId], function(_jwt, data) {
    let boosters = (data?[armyId].boosters ?? []).map(@(b) b.guid)
    console_print($"Boosters applied in army {armyId}: ", ", ".join(boosters))
    debug_apply_booster_in_battle(boosters)
  })
}

console_register_command(@(armyId) requestProfileDataJwt([armyId], @(_jwt, data)
  log.debugTableData(data, { recursionLevel = 7, printFn = debug }) ?? log("Done")),
  "profileData.debugArmyData")

console_register_command(@(pretty) saveToFile(null/*teamArmy*/, !!pretty),
  "profileData.profileToJson",
  "[pretty] If set to true, then you will get a beautiful json output")

console_register_command(debugApplyBoosterInBattle, "profileData.debugApplyBoosterInBattle")

return {
  saveToFile
  saveJwtResultToJson
  mkJwtArmiesCbNoRetries
  setNextBattleData = @(armyId, jwt, data) nextBattleData({ armyId, jwt, data })
}