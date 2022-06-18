require ecs

[es(tag=server, on_appear, REQUIRE=train_attachment__restrictToTrainOffenseTeam)]
def train_attachment_restrict_to_team(evt : Event;
                                      train_attachment__parentEid : EntityId;
                                      var team : int&;
                                      var vehicle_seats__restrictToTeam : int&)
  query(train_attachment__parentEid) <| $ [es] (train__teamOffense : int)
    vehicle_seats__restrictToTeam = train__teamOffense
    team = train__teamOffense
