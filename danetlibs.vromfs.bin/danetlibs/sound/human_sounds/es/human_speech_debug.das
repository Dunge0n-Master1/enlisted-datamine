options no_aot
require ecs
require DagorConsole
require soundSystem
require human_sounds.modules.human_sounds_events

[console_cmd(name="human_speech.start")]
def human_speech_debug_console_start(phrase : string)
  find_query() <| $ [es(REQUIRE=hero)] (eid : EntityId; human_speech__locale : string; human_speech__playerVoice : string; human_speech__enemyVoices : StringList)
    sendEvent(eid, [[CmdHeroSpeech phrase=phrase]])
    sound_debug("locale={human_speech__locale};  playerVoice={human_speech__playerVoice}; enemyVoices={human_speech__enemyVoices}")
    return true

/*
{path}/{locale}(optional)/{name}
"vo/player/enlisted/soldier/ru"
"vo/enemy/enlisted/soldier01/ru"
"vo/enemy/enlisted/soldier02/ru"
"vo/enemy/enlisted/soldier03/ru"
*/
