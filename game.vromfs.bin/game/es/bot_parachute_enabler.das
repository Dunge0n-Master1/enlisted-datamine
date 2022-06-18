require ecs

[es(tag=server, REQUIRE=squad_member__squad, on_appear, track=possessedByPlr)]
def change_parachute_height_on_possess_unpossess(evt : Event;
                                                 possessedByPlr : EntityId;
                                                 human_parachute__aiDeployHeight : float;
                                                 human_parachute__playerDeployHeight : float;
                                                 var human_parachute__autoDeployHeight : float&)
  if !possessedByPlr
    human_parachute__autoDeployHeight = human_parachute__aiDeployHeight
  else
    human_parachute__autoDeployHeight = human_parachute__playerDeployHeight