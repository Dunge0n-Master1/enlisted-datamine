module human_sounds_events shared
require ecs

[event(unicast)]
struct CmdHeroSpeech
  phrase : string

[event(unicast)]
struct CmdHumanVoiceEffect
  phrase : string
