let circuitConf = require("app").get_circuit_conf()

// store != shop
// used in Chinese version to display a link to a store in main menu alongside armies and campaign tabs
let getStoreUrl = @() circuitConf?.storeUrl

let getEventUrl = @() circuitConf?.eventUrl

return {
  getStoreUrl
  getEventUrl
}