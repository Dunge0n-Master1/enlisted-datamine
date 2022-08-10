require ecs
require game.events_game

[es]
def activate_entity(evt : EventEntityActivate; var active : bool&)
  active = evt.activate
