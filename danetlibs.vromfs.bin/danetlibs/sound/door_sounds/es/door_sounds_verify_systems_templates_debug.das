options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[es(on_event=VerifyEcsTemplates)]
def door_sound_verify_ecs_templates(evt : Event)
  req_template({{
    "door_operations__curState" => ecs_type_hash(type<bool>);
    "door_sound__openPath" => ecs_type_hash(type<string>);
    "door_sound__closePath" => ecs_type_hash(type<string>);
    "transform" => ecs_type_hash(type<float3x4>)
  }})
