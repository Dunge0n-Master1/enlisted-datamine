options no_aot
require ecs
require ecs.safe
require ecs.common
require soundSystem
require soundEvent
require DagorSystem
require DagorDebug3D
require DagorConsole
require math.color
require math.base
require strings


[es(tag=(sound, render, dev), no_order, REQUIRE=soundDebugDrawTemplate)]
def sound_debug_draw_template(act : UpdateStageInfoRenderDebug;
                              eid : EntityId;
                              transform : float3x4)
  add_debug_text_mark(transform[3], "{eid}={getEntityTemplateName(eid)}", -1, 0., E3DCOLOR(0xFFFFFFFF))


[es(tag=(sound, render, dev), no_order)]
def sound_debug_draw(act : UpdateStageInfoRenderDebug;
                     is_watched_sound : bool = false;
                     sound_tags : Object;
                     human_voice_effect__activeEffects : Object const?;
                     [[shared_comp]] human_voice_effect__allOrderedEffects : StringList const?;
                     transform : float3x4)
  if get_enable_debug_draw()
    var text = ""

    if human_voice_effect__allOrderedEffects != null && human_voice_effect__activeEffects != null

      var numEffects = 0
      for id in *human_voice_effect__allOrderedEffects
        if (*human_voice_effect__activeEffects)[string(id)] ?? false
          if numEffects == 0
            text += "voice effects: [{id}"
          else
            text += ", {id}"
          ++numEffects
      if numEffects > 0
        text += "] "

      for itFx in *human_voice_effect__activeEffects
        var exist = false
        for id in *human_voice_effect__allOrderedEffects
          exist ||= itFx.key == id
        if !exist
          text += "-'{itFx.key}' is MISSING in human_voice_effect__allOrderedEffects-"

    if is_watched_sound || length(sound_tags) > 0
      text += "sound tags:{sound_tags} "
    if !empty(text)
      let color = is_watched_sound ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF000000)
      let pos = transform[3] + float3(0., 0.5, 0.)
      add_debug_text_mark(pos, text, -1, 0., color)

    query_visual_labels() <| $(labels : array<VisualLabel>#)
      for it in labels
        add_debug_text_mark(it.pos, "radius={it.radius} name={it.name}", -1, 0., E3DCOLOR(0xFFFF00FF))


[es(tag=(sound, render, dev), REQUIRE_NOT=sound_tags, no_order)]
def sound_debug_draw_watched(act : UpdateStageInfoRenderDebug;
                             is_watched_sound : bool;
                             transform : float3x4)
  if get_enable_debug_draw()
    if is_watched_sound
      let pos = transform[3] + float3(0., 0.5, 0.)
      let color = is_watched_sound ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF000000)
      let text = "watched sound"
      add_debug_text_mark(pos, text, -1, 0., color)


[console_cmd(name="sndsys.preset_enable")]
def sound_debug_console_sndsys_preset_enable(name : string; enable : bool)
  sound_banks_enable_preset(name, enable)


[console_cmd(name="sound.play")]
def sound_debug_console_sound_play(path : string; duration = 5.)
  var handle = soundEvent::play("", path, get_listener_pos())
  if handle != invalid_sound_event_handle()
    sound_debug("sound.play '{path}' is3d={is_3d(handle)}; maxRange={get_max_distance(handle)}; isOneshot={is_oneshot(handle)}")
  if is_oneshot(handle)
    abandon(handle)
  else
    abandon(handle, duration)


[console_cmd(name="sound.enum_events")]
def sound_debug_console_enum_events()
  sound_debug_enum_events()
