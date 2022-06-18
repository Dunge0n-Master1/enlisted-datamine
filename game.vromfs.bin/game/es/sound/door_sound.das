require ecs
require soundEvent

[es(tag=sound, track=door_operations__curState)]
def door_sound_state(evt : Event;
                     door_operations__curState : bool;
                     door_operations__openedSound : string;
                     door_operations__closedSound : string;
                     transform : float3x4)
  oneshot(door_operations__curState ? door_operations__openedSound : door_operations__closedSound, transform[3])
