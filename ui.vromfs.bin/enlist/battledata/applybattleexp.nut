from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let { reward_single_player_mission } = require("%enlist/meta/clientApi.nut")

let function chargeExp(data) {
  let { singleMissionRewardId, armyId, squadsExp, soldiersExp } = data
  reward_single_player_mission(singleMissionRewardId, armyId, squadsExp.keys(), soldiersExp.keys())
}

eventbus.subscribe("charge_battle_exp_rewards", @(data) chargeExp(data))
