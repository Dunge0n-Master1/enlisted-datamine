let { send_event_bq_with_header = null } = require_optional("bigquery")
let { logerr } = require("dagor.debug")

let function sendBqBattleResult(userId, soldiersStats, expReward, armyData, armyId) {
  if (send_event_bq_with_header == null) {
    logerr("Missing bigquery module. Allowed on dedicated only.")
    return
  }
  let { baseExp, armyExp, squadsExp, soldiersExp, activity } = expReward
  let hasPrem = (armyData?.premiumExpMul ?? 1.0) > 1
  let locked = armyData?.isArmyProgressLocked ?? false

  //send army result
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("game_events_bq", {
    event_type = "army_battle_result",
    user_id    = userId,                      // int
    army       = armyId,                      // string
    baseExp    = baseExp,                     // int
    exp        = armyExp,                     // int
    prem       = hasPrem,                     // bool
    activity,                                 // float
    locked                                    // bool
  })

  foreach (squad in (armyData?.squads ?? [])) {
    //send squads result
    let squadId = squad?.squadId
    let premSquad = (squad?.battleExpBonus ?? 0) > 0
    if (squadId in squadsExp)
      // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
      send_event_bq_with_header("game_events_bq", {
        event_type = "squad_battle_result",
        user_id    = userId,                        // int
        army       = armyId,                        // string
        squad_id   = squadId,                       // string
        exp        = squadsExp[squadId],            // int
        expBonus   = squad?.expBonus ?? 0.0,        // float
        premSquad  = premSquad,                     // bool
        prem       = hasPrem                        // bool
      })

    let classBonus = armyData?.classBonus ?? {}
    foreach (soldier in (squad?.squad ?? [])) {
      let guid = soldier?.guid
      if (!(guid in soldiersExp))
        continue

      let { time, score } = soldiersStats[guid]
      let { sClass = "", level = 1 } = soldier
      // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
      send_event_bq_with_header("game_events_bq", {
        event_type       = "soldier_battle_result",
        user_id          = userId,                       // int
        army             = armyId,                       // string
        squad_id         = squadId,                      // string
        soldier_class    = sClass,                       // string
        soldier_level    = level,                        // int
        soldier_time     = time,                         // float
        score            = score,                        // int
        exp              = soldiersExp[guid],            // int
        expBonus         = classBonus?[sClass] ?? 0.0,   // float
        premSquad        = premSquad,                    // bool
        prem             = hasPrem                       // bool
      })
    }
  }
}

return sendBqBattleResult