require ecs
require soundEvent

[es(tag=sound, track=is_watched_sound)]
def watched_entity_snapshot_toggle(evt : Event;
                                   is_watched_sound : bool;
                                   watched_entity_snapshot__path : string;
                                   var watched_entity_snapshot__event : SoundEvent&)
  abandon(watched_entity_snapshot__event.handle)
  if is_watched_sound
    watched_entity_snapshot__event |> play(watched_entity_snapshot__path)
