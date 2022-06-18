require ecs
require EnlistedNet
require game.es.input.input_events
require enlisted.events_enlisted

[es(tag=input)]
def human_repair_fortification_start_input_es(evt : EventDaInputActionTriggered;
                                              eid : EntityId;
                                              human_use_object__selectedBuilding : EntityId;
                                              human_input__vehicleMaintenance : int;
                                              input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__vehicleMaintenance
    query(human_use_object__selectedBuilding) <| $ [es(REQUIRE=fortification_repair__costPercent, REQUIRE_NOT=builder_preview)] ()
      send_net_event(eid, [[EventRepairFortificationStart target=human_use_object__selectedBuilding]])

[es(tag=input)]
def human_repair_fortification_stop_input_es(evt : EventDaInputActionTerminated;
                                             eid : EntityId;
                                             human_input__vehicleMaintenance : int;
                                             input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__vehicleMaintenance
    send_net_event(eid, [[EventRepairFortificationStop]])
