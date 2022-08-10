require ecs
require game.events_game

[es(on_event=(EventEntityRevived, EventEntityResurrected))]
def enable_actions(evt : Event; var actions__enabled : bool&)
  actions__enabled = true

[es(on_event=(EventEntityDowned, EventEntityDied))]
def disable_actions(evt : Event; var actions__enabled : bool&)
  actions__enabled = false