require ecs


[es(tag=server, on_appear, REQUIRE=(hasParachute, parachuteDeployed))]
def apply_zone_trigger_tag_on_parachute_deploy(evt : Event;
                                               human_parachute__zoneTriggerTag : string = "planeTriggerable";
                                               var zones_visitor__triggerTag : das_string)
  zones_visitor__triggerTag := human_parachute__zoneTriggerTag