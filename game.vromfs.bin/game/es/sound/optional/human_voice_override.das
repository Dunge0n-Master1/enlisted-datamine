require ecs
require strings
require DagorDataBlock
require DagorSystem

def voice_override(var path : das_string&; locale : string)
  if length(path) >= 2
    path := "{slice(string(path), 0, length(path) - 2)}{locale}"

[es(tag=sound, on_appear)]
def human_voice_override(evt : Event;
                         var human_sound__playerVoice : das_string&;
                         var human_sound__npcVoices : StringList&)
  let locale = dgs_get_settings() |> datablock_get_block_by_name("sound") |> datablock_getStr("overrideVoicesLocale", "")
  if locale != ""
    voice_override(human_sound__playerVoice, locale)
    for voice in human_sound__npcVoices
      voice_override(voice, locale)
