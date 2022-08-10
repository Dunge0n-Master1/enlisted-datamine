options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[es(on_event=VerifyEcsTemplates)]
def common_human_sounds_verify_ecs_templates(evt : Event)
  // human_climb_sound (human_climb_sound.das)
  req_template({{
    "sound_tags" => ecs_type_hash(type<ecs::Object>);
    "sound_event_group" => ecs_type_hash(type<SoundEventGroup>);
    "sound_paths" => ecs_type_hash(type<ecs::Object>);
    "is_watched_sound" => ecs_type_hash(type<bool>);
    "human_net_phys__isClimbing" => ecs_type_hash(type<bool>);
    "transform" => ecs_type_hash(type<float3x4>)
  }})
