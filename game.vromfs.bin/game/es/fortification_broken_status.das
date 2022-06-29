require enlisted.events_enlisted
require game.events_game
require game.es.events
require DagorSystem
require ecs

def break_building(building_eid : EntityId;
                   offender_eid : EntityId;
                   var building__isBroken : bool&;
                   var building__breakOffender : EntityId&)
  if building__isBroken
    return
  building__isBroken = true
  building__breakOffender = offender_eid
  sendEventImmediate(building_eid, [[EventEngineerBuildingBroken offender=offender_eid]])

[es(tag=server, before=break_additive_buildings, REQUIRE_NOT=builder_preview)]
def building_broken_dismantled(evt : EventEntityDestroyed;
                               eid : EntityId;
                               building_destroy__operator : EntityId;
                               isAlive : bool = true;
                               var building__isBroken : bool&;
                               var building__breakOffender : EntityId&)
  if isAlive
    break_building(eid, building_destroy__operator, building__isBroken, building__breakOffender)

[es(tag=server, before=break_additive_buildings, REQUIRE_NOT=builder_preview)]
def building_broken_ri_destroyed(evt : EventRiExtraDestroyed;
                                 eid : EntityId;
                                 isAlive : bool = true;
                                 building_destroy__operator : EntityId = INVALID_ENTITY_ID;
                                 var building__isBroken : bool&;
                                 var building__breakOffender : EntityId&)
  if isAlive
    let offender = !!building_destroy__operator ? building_destroy__operator : evt.offenderEid
    break_building(eid, offender, building__isBroken, building__breakOffender)

[es(tag=server, before=break_additive_buildings, REQUIRE_NOT=builder_preview)]
def building_broken_died(evt : EventEntityDied;
                         eid : EntityId;
                         var building__isBroken : bool&;
                         var building__breakOffender : EntityId&)
  break_building(eid, evt.offender, building__isBroken, building__breakOffender)

[es(tag=server, on_event=(EventEntityDestroyed, EventEntityDied), before=destroy_additive_buildings_es, REQUIRE=additiveBuildings, REQUIRE_NOT=builder_preview)]
def break_additive_buildings(evt : Event;
                             eid aka parent_eid : EntityId;
                             building__breakOffender aka parent_building__breakOffender : EntityId)
  query() <| $ [es] (eid : EntityId;
                     dependsOnBuildingEid : EntityId;
                     var building__isBroken : bool&;
                     var building__breakOffender : EntityId&)
    if parent_eid == dependsOnBuildingEid
      break_building(eid, parent_building__breakOffender, building__isBroken, building__breakOffender)

[es(tag=server, REQUIRE=rallypoint)]
def log_player_rallypoint_destroyed(evt : EventEngineerBuildingBroken;
                                    buildByPlayer : EntityId)
  sendEvent(buildByPlayer, [[CmdHeroLogEvent event="your_rally_point_destroyed", text="your_rally_point_destroyed"]])
