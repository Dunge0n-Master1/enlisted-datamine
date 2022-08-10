require ecs
require soundEvent

[es(tag=sound, on_event=EventShotDry)]
def gun_shot_dry_sound(evt : Event;
                       gun_sound__isEnabled : bool;
                       gun_sound__isWatched : bool;
                       gun_shot_dry_sound__path : string;
                       sound_bank_preset_state__isValid : bool;
                       gun__owner : EntityId)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid && gun_sound__isWatched
    query(gun__owner) <| $ [es] (transform : float3x4)
      oneshot(gun_shot_dry_sound__path, transform[3])
