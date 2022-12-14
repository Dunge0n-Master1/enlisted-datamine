options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require vehicle_sounds_net.modules.vehicle_sounds_net_events


[es(tag=server, on_event=VerifyEcsTemplates)]
def vehicle_sounds_net_verify_ecs_templates(evt : Event)
  req_template({{
    "vehicle_horn_sound__endTime" => ecs_type_hash(type<float>);
    "vehicle_seats__seatEids" => ecs_type_hash(type<EidList>);
    "vehicle_horn__player" => ecs_type_hash(type<EntityId>);
    "vehicle_horn__seat" => ecs_type_hash(type<EntityId>);
    "isAlive" => ecs_type_hash(type<bool>)
  }})
  req_unique_event_handler("CmdVehicleHornRequest")
  req_unique_event_handler("CmdVehicleSoundHorn")
