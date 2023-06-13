from "%enlSqGlob/ui_library.nut" import *
let { nestWatched } = require("%dngscripts/globalState.nut")
let { EVENT_SAVE_DISABLE_NETWORK_DATA } = require("configs.nut")
let { disableNetwork } = require("%enlSqGlob/login_state.nut")
let { saveJson, loadJson } = require("%sqstd/json.nut")
let eventbus = require("eventbus")

const DISABLE_NETWORK_PROFILE = "disable_network_profile.json"

let data = (disableNetwork ? loadJson(DISABLE_NETWORK_PROFILE) : {
  items = {}
  wallposters = {}
  soldiers = {}
  soldiersLook = {}
  soldiersOutfit = {}
  squads = {}
  armies = {}
  soldierPerks = {}
  researches = {}
  armyEffects = {}
  slotsIncrease = {}
  purchasesCount = {}
  purchasesExt = {}
  receivedUnlocks = {}
  rewardedSingleMissons = {}
  premium = {}
  armyStats = {}
  activeBoosters = {}
  decorators = {}
  vehDecorators = {}
  medals = {}
  offers = {}
  metaConfig = {}
}).map(@(defValue, key) nestWatched($"PLAYER_PROFILE_{key}", defValue))

let function dumpProfile(...) {
  saveJson(DISABLE_NETWORK_PROFILE, data.map(@(w) w.value), { logger = log_for_user })
  console_print($"Current user profile saved to {DISABLE_NETWORK_PROFILE}")
}

eventbus.subscribe(EVENT_SAVE_DISABLE_NETWORK_DATA, dumpProfile)

return data