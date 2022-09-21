require ecs
require soundEvent
require soundSystem
require sound_utils.modules.sound_player_common
require game.events_game
require game.utils.team

[es(tag=sound)]
def round_result_battle_music(evt : EventTeamRoundResult;
                              round_result_battle_music__path : string;
                              var round_result_battle_music__event : SoundEvent&)
  if evt.team == get_local_player_team()
    round_result_battle_music__event |> play(round_result_battle_music__path, get_listener_pos())
    round_result_battle_music__event.abandonOnReset = true
    set_var(round_result_battle_music__event.handle, "condition", evt.isWon ? 0. : 1.)
    set_var(round_result_battle_music__event.handle, "part", 3.)
    set_var(round_result_battle_music__event.handle, "intensity", 1.)
