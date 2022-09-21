options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require soundEvent


[req_template] // human_climb_sound (human_climb_sound.das)
struct HumanWithClimpSound
  sound_tags : ecs::Object
  sound_event_group : SoundEventGroup
  sound_paths : ecs::SharedObject
  is_watched_sound : bool
  human_net_phys__isClimbing : bool
  transform : float3x4


[req_template] // human_irq_sound (human_irq_sound.das)
struct HumanIrqSound
  humanSound : ecs::Tag
  sound_event_group : SoundEventGroup
  sound_tags : ecs::Object
  sound_irqs : ecs::SharedObject
  is_watched_sound : bool
  transform : float3x4


[req_template] // human_irq_sound_voicefx (human_irq_sound.das)
struct HumanIrqSoundVoiceFx
  humanSound : ecs::Tag
  sound_event_group : SoundEventGroup
  human_voice_sound__path : SharedObject
  human_voice_sound__irqs : SharedObject
  sound_tags : ecs::Object
  is_watched_sound : bool
  transform : float3x4


[es(on_event=VerifyEcsTemplates)]
def common_human_sounds_verify_ecs_templates(evt : Event)
  req_unique_event_handler("CmdSoundGenIrq")
  req_unique_event_handler("CmdSoundVoicefxIrq")
