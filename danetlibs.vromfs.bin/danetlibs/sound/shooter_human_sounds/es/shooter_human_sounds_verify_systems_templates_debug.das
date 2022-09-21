options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[req_template] // human_aim_sound (human_aim_sound.das)
struct HumanWithAimSound
  human_net_phys__isAiming : bool
  human_weap__currentGunEid : ecs::EntityId
  sound_tags : ecs::Object
  sound_event_group : SoundEventGroup
  is_watched_sound : bool
  transform : float3x4


[req_template] // human_using_item_sound (human_using_item_sound.das)
struct HumanWithUsingItemSound
  humanSound : ecs::Tag
  human_inventory__entityToUse : ecs::EntityId
  net_sound__descs : ecs::SharedObject
  sound_event_group : SoundEventGroup
  isAlive : bool
  is_watched_sound : bool
  transform : float3x4


[req_template] // human_shell_irq_sound (human_shell_irq_sound.das)
struct HumanWithShellIrqSound
  human_weap__gunEids : ecs::EidList
  is_watched_sound : bool
  transform : float3x4
