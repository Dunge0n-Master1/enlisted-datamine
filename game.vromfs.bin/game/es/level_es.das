require ecs
require app

[es(on_event=EventLevelLoaded)]
def level_loaded_es(evt : Event;
                    var level__loadedAtTime : float&)
  level__loadedAtTime = get_sync_time()