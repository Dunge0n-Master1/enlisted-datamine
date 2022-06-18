let greenIconColor = 0xFF10C010
let orangeIconColor = 0xFFE68200
let grayIconColor = 0xFF606060

let statuses = {
  IN_BATTLE = {
    locId = "memberStatus/inBattle"
    icon = "status/in_battle_status.svg"
    iconColor = greenIconColor
  }
  IN_DEBRIEFING = {
    locId = "memberStatus/inDebriefing"
    icon = "status/in_debrieding_status.svg"
    iconColor = orangeIconColor
  }
  IN_LOBBY_READY = {
    locId = "memberStatus/inLobbyReady"
    icon = "status/ready_status_svg.svg"
    iconColor = greenIconColor
  }
  IN_LOBBY_NOT_READY = {
    locId = "memberStatus/inLobbyNotReady"
    icon = "status/not_ready_status.svg"
    iconColor = grayIconColor
  }
}
  .map(@(s, id) s.__update({ id }))

return statuses