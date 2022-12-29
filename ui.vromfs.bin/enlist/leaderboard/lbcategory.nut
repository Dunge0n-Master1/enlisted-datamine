from "%enlSqGlob/ui_library.nut" import *

#explicit-this

let lbDataType = require("%enlSqGlob/leaderboard/lbDataType.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let makeType = @(id, params) {
  id
  field = id.tolower() //field name on server
  dataType = lbDataType.NUM
  locId = ""
  relWidth = 1.0

  function getText(rowData) {
    return this.dataType.getText(this.getValue(rowData))
  }

  function getValue(rowData) {
    local res = rowData?[this.field]
    if (typeof res == "table")
      res = res?["value_total"]
    return res
  }
}.__update(params)

let getServerTime = @() serverTime.value

let categoriesBase = {
  RANK = {
    field = "idx"
    dataType = lbDataType.PLACE
    locId = "lb/rank"
    relWidth = 0.8
  }

  NAME = {
    field = "name"
    dataType = lbDataType.NICKNAME
    locId = "lb/name"
    relWidth = 3.5
  }

  VICTORIES_PERCENT = {
    field = "victories_percent"
    dataType = lbDataType.PERCENT_FROM_INT
    locId = "lb/victories_battles"
    icon = "ui/skin#victories_battles.svg"
  }

  VICTORY_BOOL = {
    field = "victories"
    dataType = lbDataType.VICTORY_BOOL
    locId = "lb/battleResults"
    icon = "ui/skin#victories_battles.svg"
  }

  KILL_DEATH_RATIO = {
    field = "kill_death_ratio"
    dataType = lbDataType.RATIO_FROM_INT
    locId = "lb/kill_death"
    icon = "ui/skin#kill_death.svg"
  }

  BATTLES = {
    field = "battles_with_quits"
    locId = "lb/battles"
    icon = "ui/skin#battles.svg"
  }

  BATTLE_RATING = {
    field = "battle_rating"
    locId = "lb/battle_rating"
    icon = "ui/skin#battle_rating.svg"
  }

  TOURNAMENT_BATTLE_RATING = {
    field = "new_year_tournament_battle_rating"
    locId = "lb/new_year_tournament_battle_rating"
    icon = "ui/skin#battle_rating.svg"
  }

  KILLS_USING_AIRCRAFT = {
    field = "kills_using_aircraft"
    locId = "lb/aircraft_kills"
    icon = "ui/skin#kills_using_aircraft.svg"
  }

  KILLS_USING_TANK = {
    field = "kills_using_tank"
    locId = "lb/tank_kills"
    icon = "ui/skin#kills_using_tank.svg"
  }

  KILLS = {
    field = "kills"
    locId = "lb/totalKills"
    icon = "ui/skin#kills.svg"
  }

  SCORE = {
    field = "battle_score"
    locId = "lb/score"
    icon = "ui/skin#score.svg"
  }

  BATTLE_GROUP_SCORE = {
    field = "battle_group_battle_score"
    locId = "lb/battleGroupScore"
    icon = "ui/skin#squad_score.svg"
  }

  BATTLE_TIME = {
    field = "battle_time"
    dataType = lbDataType.TIME_HOURS
    locId = "lb/battleTime"
    icon = "ui/skin#battlepass/boost_time.svg"
  }

  TIME_AFTER_BATTLE = {
    field = "timestamp"
    dataType = lbDataType.TIME_HOURS
    locId = "lb/timeAfterBattle"
    relWidth = 2.0
    getText = @(rowData) this.dataType.getText(getServerTime() - this.getValue(rowData))
    getValue = @(rowData) rowData?[this.field] ?? 0
  }

  BATTLE_RATING_PENALTY = {
    field = "battle_rating_battle_quits_penalty"
    dataType = lbDataType.RATING_PENALTY
    locId = "lb/rating_penalty"
    icon = "ui/skin#friendly_fire.svg"
  }
}

let categories = categoriesBase.map(@(cat, id) cat.__update(makeType(id, cat))) //to allow links on other categories above

return categories
