require ecs
require game.utils.team
require player
require soundSystem
require strings


def narrator_set_language(army : string; player_team : int)
  query() <| $ [es] (narrator_settings__nativeLang : bool;
                     narrator_settings__banksPresetStartsWith : string)
    var preset = ""
    if narrator_settings__nativeLang && player_team != TEAM_UNASSIGNED
      query() <| $ [es] (armyLanguage : Object)
        let language = get_string(armyLanguage, army, "")
        if !empty(language)
          preset = "{narrator_settings__banksPresetStartsWith}{language}"
      if empty(preset)
        find_query() <| $ [es] (team__id : int; team__lang : string)
          if player_team == team__id
            if !empty(team__lang)
              preset = "{narrator_settings__banksPresetStartsWith}{team__lang}"
            return true
          return false

    if preset == "" || !sound_banks_is_preset_enabled(preset)
      sound_banks_enable_preset_starting_with(narrator_settings__banksPresetStartsWith, false)
      if !empty(preset)
        sound_banks_enable_preset(preset, true)


[es(tag=sound, on_appear, track=(team, is_local, army), REQUIRE=player)]
def team_narrator_language_created(evt : Event; is_local : bool; army : string; team : int)
  if is_local
    narrator_set_language(army, team)


[es(tag=sound, track=narrator_settings__nativeLang, on_appear, REQUIRE=narrator_settings__nativeLang)]
def team_narrator_language_set(evt : Event)
  query(get_local_player_eid()) <| $ [es] (army : string; team : int)
    narrator_set_language(army, team)
