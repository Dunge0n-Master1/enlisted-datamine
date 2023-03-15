module common_sounds_events shared
require ecs

[cpp_event(unicast)]
struct CmdSoundGenIrq
  irq : string

[cpp_event(unicast)]
struct CmdSoundSpecificIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdSoundVoicefxIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdSoundStepIrq
  objIdx : int
