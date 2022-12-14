require ecs
require soundEvent
require soundSystem
require sound_utils.modules.sound_player_common
require game.events_game
require game.utils.team
require DagorSystem
require DagorDataBlock


[es(tag=sound, on_appear)]
def battle_music_enabled_init(evt : Event; var battle_music__enabled : bool&)
  battle_music__enabled = dgs_get_settings() |> datablock_get_block_by_name("sound") |> datablock_getBool("battle_music_enabled", true)


[es(tag=sound, track=battle_music__enabled)]
def battle_music_enabled_track(evt : Event;
                               battle_music__enabled : bool;
                               var battle_music__event : SoundEvent&)
  if !battle_music__enabled
    release(battle_music__event.handle)


[es(tag=sound, REQUIRE=player, on_event=EventHeroChanged)]
def battle_music_intro(evt : Event)
  query() <| $ [es] (battle_music__intro : string;
                     battle_music__enabled : bool;
                     var battle_music__shouldStartIntro : bool&;
                     var battle_music__event : SoundEvent&)
    if battle_music__shouldStartIntro
      battle_music__shouldStartIntro = false
      battle_music__event.abandonOnReset = true
      if battle_music__enabled
        battle_music__event |> play(battle_music__intro, get_listener_pos())


[es(tag=sound)]
def battle_music_outro(evt : EventTeamRoundResult;
                       battle_music__outro : string;
                       var battle_music__shouldStartIntro : bool&;
                       var battle_music__event : SoundEvent&)
  if evt.team == get_local_player_team()
    release(battle_music__event.handle)
    battle_music__event |> play(battle_music__outro, get_listener_pos())
    battle_music__event.abandonOnReset = true
    battle_music__shouldStartIntro = false

    set_var(battle_music__event.handle, "condition", evt.isWon ? 0. : 1.)
    set_var_optional(battle_music__event.handle, "part", 3.)
    set_var_optional(battle_music__event.handle, "intensity", 1.)
