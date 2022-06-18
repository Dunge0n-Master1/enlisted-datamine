require ecs

[es(tag=server, on_appear)]
def zones_visitor_init_last_trigger_tag(evt : Event; zones_visitor__triggerTag : string;
                                        var zones_visitor__lastTriggerTag : das_string)
  zones_visitor__lastTriggerTag := zones_visitor__triggerTag

[es(tag=server, track=(isInVehicle, human_net_phys__isInAir), on_appear, after=zones_visitor_init_last_trigger_tag)]
def zones_visitor_vehicle_overload_trigger_tag_es(evt : Event;
                                                  isInVehicle : bool;
                                                  human_net_phys__isInAir : bool;
                                                  human_anim__vehicleSelected : EntityId;
                                                  var zones_visitor__triggerTag aka visitor_zones_visitor__triggerTag : das_string;
                                                  var zones_visitor__lastTriggerTag : das_string)
  if isInVehicle
    ecs::query(human_anim__vehicleSelected) <| $ [es(REQUIRE=overloadZonesVisitorTriggerTag)] (zones_visitor__triggerTag : string)
      if visitor_zones_visitor__triggerTag != zones_visitor__triggerTag
        zones_visitor__lastTriggerTag := visitor_zones_visitor__triggerTag
        visitor_zones_visitor__triggerTag := zones_visitor__triggerTag
  elif !human_net_phys__isInAir
    zones_visitor__triggerTag := zones_visitor__lastTriggerTag
