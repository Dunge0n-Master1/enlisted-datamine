let circuitConf = require("app").get_circuit_conf()

// store != shop
// used in Chinese version to display a link to a store in main menu alongside armies and campaign tabs
let getStoreUrl = @() circuitConf?.storeUrl

let getEventUrl = @() circuitConf?.eventUrl
let getPremiumUrl = @() circuitConf?.premiumUrl
let getBattlePassUrl = @() circuitConf?.battlePassUrl
let getSquadCashUrl = @() circuitConf?.squadCashUrl

return {
  getStoreUrl
  getEventUrl
  getPremiumUrl
  getBattlePassUrl
  getSquadCashUrl
}
