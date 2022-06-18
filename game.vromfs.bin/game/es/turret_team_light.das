require ecs
require DagorMath
require game.utils.team


[es(tag=gameClient, on_appear)]
def create_team_light_on_turrets(evt : Event;
                                 transform : float3x4;
                                 team : int;
                                 turret__teamLightTemplate : string;
                                 turret__enemyTeamLight : E3DCOLOR;
                                 turret__allyTeamLight : E3DCOLOR;
                                 var turret__teamLightEid : EntityId&;
                                 turret__teamLightHeightOffset : float = 2.5)
  if turret__teamLightEid == INVALID_ENTITY_ID
    turret__teamLightEid = createEntity(turret__teamLightTemplate) <| $(init)
      var tm = transform
      tm[2] = -transform[1]
      tm[1] = transform[0]
      tm[0] = transform[2]
      tm[3] += transform[1] * turret__teamLightHeightOffset
      init |> set("transform", tm)
      let color = is_teams_friendly(team, get_local_player_team()) ? turret__allyTeamLight : turret__enemyTeamLight
      init |> set("light__color", color)

[es(tag=gameClient, on_disappear)]
def destroy_team_light_on_turrets(evt : Event;
                                  turret__teamLightEid : EntityId)
  destroyEntity(turret__teamLightEid)