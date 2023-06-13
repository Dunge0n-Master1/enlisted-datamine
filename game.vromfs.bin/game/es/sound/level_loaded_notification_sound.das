require ecs
require soundEvent


[es(on_event=EventLevelLoaded)]
def level_loaded_notification_sound(evt : Event)
  if !(find_query() <| $ [es(REQUIRE=menu_level)] () => true)
    oneshot("ui/match_loaded")
