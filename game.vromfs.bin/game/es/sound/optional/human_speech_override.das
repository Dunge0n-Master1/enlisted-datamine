require ecs
require strings
require DagorDataBlock
require DagorSystem


[es(tag=sound, on_appear)]
def human_speech_override(evt : Event;
                          var human_speech__locale : das_string&)
  let locale = dgs_get_settings() |> datablock_get_block_by_name("sound") |> datablock_getStr("overrideVoicesLocale", "")
  if !empty(locale)
    human_speech__locale := locale
