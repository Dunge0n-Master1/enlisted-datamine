require ecs
require soundEvent
require soundSystem


[es(tag=sound, track=is_watched_sound)]
def watched_entity_snapshot_toggle(evt : Event;
                                   is_watched_sound : bool;
                                   watched_entity_snapshot__path : string;
                                   var watched_entity_snapshot__event : SoundEvent&)
  abandon(watched_entity_snapshot__event.handle)
  if is_watched_sound
    watched_entity_snapshot__event |> play(watched_entity_snapshot__path, get_listener_pos())


[es(tag=sound, REQUIRE=(watchedEntitySnapshot3d, vehicleWithWatched), no_order)]
def watched_entity_snapshot_update(evt : UpdateStageInfoAct;
                                   watched_entity_snapshot__event : SoundEvent)
  set_pos(watched_entity_snapshot__event.handle, get_listener_pos())
