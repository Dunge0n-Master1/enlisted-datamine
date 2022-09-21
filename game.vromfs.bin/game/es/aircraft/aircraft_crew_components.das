require ecs

[es(on_appear, track=human_anim__vehicleSelected, REQUIRE_NOT=aircraftCrew)]
def aircraft_crew_components_add(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  if has(human_anim__vehicleSelected, "airplane")
    addSubTemplate(eid, "aircraft_crew_components")

[es(on_appear, track=human_anim__vehicleSelected, REQUIRE=aircraftCrew)]
def aircraft_crew_components_remove(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  if !has(human_anim__vehicleSelected, "airplane")
    removeSubTemplate(eid, "aircraft_crew_components")
