require ecs
require soundEvent
require soundSystem


[es(tag=sound, track=is_watched_sound)]
def watched_entity_snapshot_toggle(evt : Event;
                                   is_watched_sound : bool;
                                   watched_entity_snapshot__path : string;
                                   var watched_entity_snapshot__event : SoundEvent&;
                                   transform : float3x4 const?)
  abandon(watched_entity_snapshot__event.handle)
  if is_watched_sound
    watched_entity_snapshot__event |> play(watched_entity_snapshot__path, transform != null ? (*transform)[3] : get_listener_pos())


[es(tag=sound, REQUIRE=(watchedEntitySnapshot3d, vehicleWithWatched), on_event=ParallelUpdateFrameDelayed, after=animchar_render_es)]
def watched_entity_snapshot_update(evt : Event;
                                   watched_entity_snapshot__event : SoundEvent;
                                   transform : float3x4)
  set_pos(watched_entity_snapshot__event.handle, transform[3])
