let { TEAM_UNASSIGNED } = require("team")
let function is_teams_friendly(team1_id, team2_id){
  return team1_id == team2_id && team1_id !=TEAM_UNASSIGNED
}
return is_teams_friendly