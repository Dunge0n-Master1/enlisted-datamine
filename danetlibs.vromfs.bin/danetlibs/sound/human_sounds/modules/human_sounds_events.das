module human_sounds_events shared
require ecs

[cpp_event(unicast)]
struct CmdSoundVoicefxIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdSoundStepIrq
  objIdx : int
