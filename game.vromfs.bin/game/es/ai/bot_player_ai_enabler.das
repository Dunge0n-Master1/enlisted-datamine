require ecs
require app

[es(tag=server, on_appear, before=switch_ai_on_possess_unpossess)]
def server_toggle_ai_es(evt : Event; ai_enabled__inGame : bool; var ai_enabled : bool&)
  if !get_app_offline_mode() // not in editor
    ai_enabled = ai_enabled__inGame

[es(tag=server, track=possessed, REQUIRE=botAiEnabler)]
def bot_player_ai_enabler_es(evt : Event; possessed : ecs::EntityId)
  ecs::query(possessed) <| $ [es] (var beh_tree__enabled : bool&; ai_enabled : bool = true)
    beh_tree__enabled = ai_enabled
