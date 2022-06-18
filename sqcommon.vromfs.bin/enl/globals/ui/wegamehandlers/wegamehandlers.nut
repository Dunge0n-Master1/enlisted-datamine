let { exit_game } = require("app")
let eventbus = require("eventbus")

// it does not require any messages, because wegame launcher will show them by itself
eventbus.subscribe("wegame.quit", @(_) exit_game())
