options no_aot
require ecs
require ecs.safe
require ecs.common
require soundSystem
require DagorSystem
require DagorDebug3D
require DagorConsole
require math.color
require strings
require soundEvent


[es(tag=(sound, render), no_order)]
def sound_debug_draw(act : UpdateStageInfoRenderDebug;
                     is_watched_sound : bool = false;
                     sound_tags : Object;
                     human_voice_effect__activeEffects : Object const?;
                     transform : float3x4)
  if get_enable_debug_draw()
    var text = ""
    if human_voice_effect__activeEffects != null && !empty(*human_voice_effect__activeEffects)
      text = "active effects:{*human_voice_effect__activeEffects} "
    if is_watched_sound || length(sound_tags) > 0
      text += "sound tags:{sound_tags} "
    if !empty(text)
      let color = is_watched_sound ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF000000)
      let pos = transform[3] + float3(0., 0.5, 0.)
      add_debug_text_mark(pos, text, -1, 0., color)

    query_visual_labels() <| $(labels : array<VisualLabel>#)
      for it in labels
        add_debug_text_mark(it.pos, "radius={it.radius} name={it.name}", -1, 0., E3DCOLOR(0xFFFF00FF))


[es(tag=(sound, render), REQUIRE_NOT=sound_tags, no_order)]
def sound_debug_draw_watched(act : UpdateStageInfoRenderDebug;
                             is_watched_sound : bool;
                             transform : float3x4)
  if get_enable_debug_draw()
    if is_watched_sound
      let pos = transform[3] + float3(0., 0.5, 0.)
      let color = is_watched_sound ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF000000)
      let text = "watched sound"
      add_debug_text_mark(pos, text, -1, 0., color)


[console_cmd(name="sndsys.preset_load")]
def sound_debug_console_sndsys_preset_load(name : string; load : bool)
  sound_banks_load_preset(name, load)
