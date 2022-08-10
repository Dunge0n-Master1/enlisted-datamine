options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[es(on_event=VerifyEcsTemplates)]
def shooter_human_sounds_verify_ecs_templates(evt : Event)
  // human_aim_sound (human_aim_sound.das)
  req_template({{
    "human_net_phys__isAiming" => ecs_type_hash(type<bool>);
    "human_weap__currentGunEid" => ecs_type_hash(type<ecs::EntityId>);
    "sound_event_group" => ecs_type_hash(type<SoundEventGroup>);
    "sound_tags" => ecs_type_hash(type<ecs::Object>);
    "is_watched_sound" => ecs_type_hash(type<bool>);
    "transform" => ecs_type_hash(type<float3x4>)
  }})
