require ecs
require DagorSystem
require DagorDataBlock


[es(on_appear)]
def init_headshot_sound_enabled_es(evt : Event; var human_hit_sound__headshotSoundEnabled : bool&)
  human_hit_sound__headshotSoundEnabled = dgs_get_settings() |> datablock_get_block_by_name("sound") |> datablock_getBool("headshot_sound_enabled", true)
