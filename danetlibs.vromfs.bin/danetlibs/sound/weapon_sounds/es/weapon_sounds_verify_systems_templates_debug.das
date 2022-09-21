options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent
require DagorMath
require Gun


[es(on_event=VerifyEcsTemplates)]
def weapon_sounds_verify_ecs_templates(evt : Event)
  // gun_shot_dry_sound (gun_shot_dry_sound.das)
  req_template({{
    "gun_sound__isEnabled" => ecs_type_hash(type<bool>);
    "gun_sound__isWatched" => ecs_type_hash(type<bool>);
    "gun_shot_dry_sound__path" => ecs_type_hash(type<string>);
    "sound_bank_preset_state__isValid" => ecs_type_hash(type<bool>);
    "gun__owner" => ecs_type_hash(type<ecs::EntityId>)
  }})
  req_unique_event_handler("EventShotDry")

  // gun_sound_is_watched_update (gun_sound_is_watched.das)
  req_template({{
    "gun_sound__isWatched" => ecs_type_hash(type<bool>);
    "gun__owner" => ecs_type_hash(type<ecs::EntityId>)
  }})

  // gun_switch_firing_mode_sound (gun_switch_firing_mode_sound.das)
  req_template({{
    "animchar_bbox" => ecs_type_hash(type<bbox3f>);
    "gun_sound__isEnabled" => ecs_type_hash(type<bool>);
    "gun_switch_firing_mode_sound__path" => ecs_type_hash(type<string>);
    "sound_bank_preset_state__isValid" => ecs_type_hash(type<bool>);
    "gun_sound__isWatched" => ecs_type_hash(type<bool>)
  }})

  // play_projectile_hit_scene_sound (play_projectile_hit_scene_sound.das)
  req_template({{
    "projectile_sound__hit" => ecs_type_hash(type<string>);
    "projectile_sound__explode" => ecs_type_hash(type<string>)
  }})
  req_unique_event_handler("CmdPlayProjectileHitSceneSound")
