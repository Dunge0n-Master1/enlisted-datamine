require ecs

[es(tag=server, on_appear, before=destroy_building_with_cost_resctriction)]
def building_with_cost_init(evt : Event;
                            maxCostReturnedOnDestructionMul : float;
                            var costReturnedOnDestructionMul : float&)
  costReturnedOnDestructionMul = maxCostReturnedOnDestructionMul

[es(tag=server, on_appear, REQUIRE=costReturnedOnDestructionMul)]
def create_building_with_cost_resctriction(evt : Event;
                                           buildByEngineerEid : EntityId;
                                           buildingCost : float)
  query(buildByEngineerEid) <| $ [es] (var stockOfBuilderCapabilities : float&)
    stockOfBuilderCapabilities -= buildingCost

[es(tag=server, on_event=(EventEntityDestroyed, EventEntityDied))]
def destroy_building_with_cost_resctriction(evt : Event;
                                            buildByEngineerEid : EntityId;
                                            buildingCost : float;
                                            costReturnedOnDestructionMul : float)
  query(buildByEngineerEid) <| $ [es] (var stockOfBuilderCapabilities : float&)
    stockOfBuilderCapabilities += buildingCost * costReturnedOnDestructionMul