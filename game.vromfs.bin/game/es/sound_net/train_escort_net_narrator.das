require ecs
require game.utils.team

[es(tag=server, no_order)]
def train_escort_net_narrator(info : UpdateStageInfoAct;
                              train__teamOffense : int;
                              train__teamDefense : int;
                              var train_escort_narrator__teamOffensePresence : int&;
                              var train_escort_narrator__teamDefensePresence : int&)
  train_escort_narrator__teamOffensePresence = -1
  train_escort_narrator__teamDefensePresence = -1
  query() <| $ [es] (teamPresence : Object)
    let offense = get_ecs_array(teamPresence, "{train__teamOffense}")
    let defense = get_ecs_array(teamPresence, "{train__teamDefense}")
    train_escort_narrator__teamOffensePresence = offense != null && length(*offense) > 0 ? train__teamOffense : -1
    train_escort_narrator__teamDefensePresence = defense != null && length(*defense) > 0 ? train__teamDefense : -1
    if train_escort_narrator__teamOffensePresence == TEAM_UNASSIGNED
      train_escort_narrator__teamOffensePresence = -1
    if train_escort_narrator__teamDefensePresence == TEAM_UNASSIGNED
      train_escort_narrator__teamDefensePresence = -1
