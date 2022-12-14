options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[req_template]
struct HumanWithClimpSound
  sound_tags : ecs::Object
  sound_event_group : SoundEventGroup
  sound_paths : ecs::SharedObject
  is_watched_sound : bool
  human_net_phys__isClimbing : bool
  transform : float3x4


[req_template]
struct HumanIrqSound
  humanSound : ecs::Tag
  sound_event_group : SoundEventGroup
  sound_tags : ecs::Object
  sound_irqs : ecs::SharedObject
  is_watched_sound : bool
  transform : float3x4


[req_template]
struct HumanIrqSoundVoiceFx
  humanSound : ecs::Tag
  sound_event_group : SoundEventGroup
  human_voice_sound__path : SharedObject
  human_voice_sound__irqs : SharedObject
  sound_tags : ecs::Object
  is_watched_sound : bool
  transform : float3x4


[req_template]
struct HumanDeathSound
  human_voice_sound__path : SharedObject
  human_voice_sound__descs : SharedObject
  sound_event_group : SoundEventGroup
  sound_tags : ecs::Object
  transform : float3x4


[req_template]
struct HumanFallSound
  human_net_phys__isUnderwater : bool
  human_net_phys__deltaVelIgnoreAmount : float
  human_net_phys__velocity : float3
  human_fall_sound__isFalling : bool
  human_fall_sound__threshold : float


[req_template]
struct HumanIdleSoundRequiredComponents
  sound_control__shouldPlay : bool
  sound_tags : Object
  is_watched_sound : bool
  transform : float3x4
  isAlive : bool
  isDowned : bool


[es(on_event=VerifyEcsTemplates)]
def human_sounds_verify_ecs_templates(evt : Event)
  req_unique_event_handler("CmdSoundGenIrq")
  req_unique_event_handler("CmdSoundVoicefxIrq")
