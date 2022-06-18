require enlisted.game.es.fortifications_build_common
require game.es.battle_area_common
require game.utils.team
require zones
require ecs

def check_outside_battle_area_buildings()
  query() <| $ [es] (transform : float3x4;
                     buildTypeId : int;
                     buildingCost : float;
                     costReturnedOnDestructionMul : float;
                     var buildByPlayer : EntityId&;
                     var buildByEngineerEid : EntityId&)
    let playerTeam = get_int(buildByPlayer, "team") ?? TEAM_UNASSIGNED
    if is_tm_outside_battle_area(transform, playerTeam)
      change_building_limits(buildByPlayer, buildTypeId, 1)
      query(buildByEngineerEid) <| $ [es] (var stockOfBuilderCapabilities : float&)
        stockOfBuilderCapabilities += buildingCost * costReturnedOnDestructionMul
      buildByPlayer = INVALID_ENTITY_ID
      buildByEngineerEid = INVALID_ENTITY_ID

[es(tag=server, REQUIRE=(battle_area, humanTriggerable), on_event=EventEntityDestroyed)]
def out_battle_area_buildings_check(evt : Event)
  check_outside_battle_area_buildings()

[es(tag=server, track=active, REQUIRE=(battle_area, humanTriggerable))]
def out_battle_area_buildings_deactivate_check(evt : Event; active : bool)
  if !active
    check_outside_battle_area_buildings()